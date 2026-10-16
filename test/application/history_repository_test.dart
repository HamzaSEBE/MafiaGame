import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/data/repositories/history_repository.dart';
import 'package:mafia_nightfall/data/repositories/game_results_repository.dart';
import 'package:mafia_nightfall/data/repositories/result_receipt.dart';
import 'package:game_core/game_core.dart';
import '../support/memory_firestore.dart';

GameRecord record(String id, {int day = 1}) => GameRecord(
  id: id,
  date: DateTime(2026, 10, day),
  winningTeam: 'citizens',
  players: [
    PlayerRecord(name: 'Citizen', roleName: 'citizen', team: 'citizens'),
  ],
  newspaperText: 'full report',
  gameStateJson: {'events': 'large payload'},
);

void main() {
  late MemoryFirestore db;
  late MemoryAuth auth;
  late HistoryRepository history;
  setUp(() {
    db = MemoryFirestore();
    auth = MemoryAuth('account');
    history = HistoryRepository(firestore: db, auth: auth);
  });
  const user = 'users/account';
  test(
    'lean summaries paginate in date order; details read only on demand',
    () async {
      for (var i = 1; i <= 25; i++) {
        await history.addGame(record('g$i', day: i));
      }
      db.reads.clear();
      final first = await history.getHistoryPage();
      expect(first.records.length, 12);
      expect(first.hasMore, true);
      expect(first.records.first.id, 'g25');
      expect(db.reads, ['$user/games/*']);
      expect(db.queryLimits, [13]);
      expect(jsonEncode(db.documents['$user/games/g25']).length, lessThan(250));
      expect(
        db.documents['$user/games/g25']!.keys,
        isNot(contains('gameStateJson')),
      );
      final second = await history.getHistoryPage(after: first.cursor);
      final third = await history.getHistoryPage(after: second.cursor);
      expect(
        [
          ...first.records,
          ...second.records,
          ...third.records,
        ].map((e) => e.id).toSet().length,
        25,
      );
      expect(third.hasMore, false);
      expect((await history.getGame('g25'))!.newspaperText, 'full report');
      expect(db.reads.last, '$user/gameDetails/g25');
      await expectLater(history.getHistoryPage(pageSize: 0), throwsRangeError);
    },
  );
  test(
    'permanent deletion removes all raw game data, retains stats and rejects result replay',
    () async {
      final result = GameResultsRepository(firestore: db, auth: auth);
      final state = GameState(
        id: 'g',
        winner: Team.citizens,
        players: [
          Player(
            id: 'c',
            name: 'Citizen',
            role: Role.goodCitizen,
            createdAt: DateTime(2026),
          ),
        ],
      );
      await result.save(record('g'), state);
      final stats = Map.of(db.documents['$user/stats/career']!);
      db.documents['$user/gameResults/g'] = {'recordedAt': 'old date'};
      db.documents['$user/gameResultsV2/g'] = {'recordedAt': 'old date'};
      await history.deleteGame('g');
      expect(db.documents.keys.where((p) => p.endsWith('/g')), isEmpty);
      expect(db.documents['$user/stats/career'], stats);
      final receiptPath =
          '$user/resultReceipts/${resultReceiptId('account', 'g')}';
      expect(db.documents[receiptPath], {'processed': true});
      expect(
        resultReceiptId('account', 'g'),
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      final commitCount = db.commits.length;
      await result.save(record('g'), state);
      expect(db.commits.length, commitCount);
      expect(await history.getGame('g'), isNull);
      expect(db.documents['$user/stats/career'], stats);
    },
  );
  test(
    'failed atomic delete keeps every match document; retry succeeds',
    () async {
      await history.addGame(record('g'));
      db.failCommit = true;
      await expectLater(history.deleteGame('g'), throwsStateError);
      expect(db.documents.containsKey('$user/games/g'), true);
      expect(db.documents.containsKey('$user/gameDetails/g'), true);
      db.failCommit = false;
      await history.deleteGame('g');
      expect(await history.getGame('g'), isNull);
    },
  );
  test(
    'clear uses bounded batches and removes legacy orphan reports and markers',
    () async {
      for (var i = 1; i <= 8; i++) {
        await history.addGame(record('g$i', day: i));
      }
      db.documents['$user/gameDetails/orphan'] = record('orphan').toJson();
      db.documents['$user/gameResults/legacy'] = {'recordedAt': 'old'};
      db.documents['$user/gameResultsV2/legacy2'] = {'recordedAt': 'old'};
      db.documents['$user/stats/career'] = {'gamesPlayed': 8};
      db.commits.clear();
      await history.clearHistory();
      expect(
        db.documents.keys.every(
          (p) => p.contains('/stats/') || p.contains('/resultReceipts/'),
        ),
        true,
      );
      expect(db.documents['$user/stats/career'], {'gamesPlayed': 8});
      expect(db.commits.every((writes) => writes.length <= 15), true);
      expect((await history.getHistoryPage()).records, isEmpty);
    },
  );
  test(
    'legacy migration preserves report and a concurrent delete cannot resurrect it',
    () async {
      db.documents['$user/games/old'] = record('old').toJson();
      await history.getHistoryPage();
      await Future<void>.delayed(Duration.zero);
      expect(db.documents['$user/games/old']!['schemaVersion'], 2);
      expect((await history.getGame('old'))!.newspaperText, 'full report');
      final gate = Completer<void>();
      db.beforeTransaction = () => gate.future;
      db.documents['$user/games/race'] = record('race', day: 2).toJson();
      await history.getHistoryPage();
      await history.deleteGame('race');
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(db.documents.containsKey('$user/games/race'), false);
      expect(db.documents.containsKey('$user/gameDetails/race'), false);
    },
  );
  test(
    'deletion purges owned finished QR children before their parent, keeps active/unowned rooms',
    () async {
      await history.addGame(record('qr'));
      db.documents['sessions/qr'] = {
        'hostUid': 'account',
        'status': 'finished',
      };
      for (final name in [
        'hostState',
        'actionRequests',
        'joinRequests',
        'secrets',
        'seats',
        'members',
      ]) {
        db.documents['sessions/qr/$name/child'] = {'private': 'data'};
      }
      await history.deleteGame('qr');
      expect(
        db.documents.keys.where((p) => p.startsWith('sessions/qr')),
        isEmpty,
      );
      for (final status in ['active', 'finished']) {
        db.documents['sessions/other'] = {
          'hostUid': status == 'active' ? 'account' : 'other',
          'status': status,
        };
        await history.addGame(record('other'));
        await history.deleteGame('other');
        expect(db.documents.containsKey('sessions/other'), true);
      }
    },
  );
}
