import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:mafia_nightfall/data/repositories/result_receipt.dart';

class PlayerRecord {
  final String name;
  final String roleName;
  final String team;

  PlayerRecord({
    required this.name,
    required this.roleName,
    required this.team,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'roleName': roleName,
    'team': team,
  };

  factory PlayerRecord.fromJson(Map<String, dynamic> json) => PlayerRecord(
    name: json['name'] as String,
    roleName: json['roleName'] as String,
    team: json['team'] as String,
  );
}

class GameRecord {
  final String id;
  final DateTime date;
  final String winningTeam;
  final List<PlayerRecord> players;
  final String newspaperText;
  final Map<String, dynamic>? gameStateJson;

  GameRecord({
    required this.id,
    required this.date,
    required this.winningTeam,
    required this.players,
    required this.newspaperText,
    this.gameStateJson,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'winningTeam': winningTeam,
    'players': players.map((p) => p.toJson()).toList(),
    'newspaperText': newspaperText,
    'gameStateJson': gameStateJson,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    winningTeam: json['winningTeam'] as String,
    players: (json['players'] as List)
        .map((p) => PlayerRecord.fromJson(p as Map<String, dynamic>))
        .toList(),
    newspaperText: json['newspaperText'] as String,
    gameStateJson: json['gameStateJson'] as Map<String, dynamic>?,
  );
}

/// Small list entry. Full participants, events and newspaper load on demand.
class GameSummary {
  const GameSummary({
    required this.id,
    required this.date,
    required this.winningTeam,
    required this.playerCount,
  });
  final String id;
  final DateTime date;
  final String winningTeam;
  final int playerCount;
  factory GameSummary.fromRecord(GameRecord record) => GameSummary(
    id: record.id,
    date: record.date,
    winningTeam: record.winningTeam,
    playerCount: record.players.length,
  );
  factory GameSummary.fromData(String id, Map<String, dynamic> data) =>
      GameSummary(
        id: id,
        date: DateTime.parse(data['date'] as String),
        winningTeam: data['winningTeam'] as String,
        playerCount:
            (data['playerCount'] as num?)?.toInt() ??
            (data['players'] as List?)?.length ??
            0,
      );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'id': id,
    'date': date.toIso8601String(),
    'winningTeam': winningTeam,
    'playerCount': playerCount,
  };
}

class HistoryPage {
  const HistoryPage({
    required this.records,
    this.cursor,
    required this.hasMore,
  });
  final List<GameSummary> records;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class HistoryRepository {
  HistoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _providedFirestore = firestore,
      _providedAuth = auth;
  final FirebaseFirestore? _providedFirestore;
  final FirebaseAuth? _providedAuth;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  String? get _uid => (_providedAuth ?? FirebaseAuth.instance).currentUser?.uid;
  Future<void> _migrations = Future<void>.value();
  final Set<String> _queuedMigrations = {};

  DocumentReference<Map<String, dynamic>> _account(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<HistoryPage> getHistoryPage({
    DocumentSnapshot<Map<String, dynamic>>? after,
    int pageSize = 12,
  }) async {
    if (pageSize < 1 || pageSize > 100) {
      throw RangeError.range(pageSize, 1, 100, 'pageSize');
    }
    final uid = _uid;
    if (uid == null) return const HistoryPage(records: [], hasMore: false);
    Query<Map<String, dynamic>> query = _account(
      uid,
    ).collection('games').orderBy('date', descending: true);
    if (after != null) query = query.startAfterDocument(after);
    final snapshot = await query.limit(pageSize + 1).get();
    final documents = snapshot.docs.take(pageSize).toList();
    final records = <GameSummary>[];
    for (final doc in documents) {
      final data = doc.data();
      records.add(GameSummary.fromData(doc.id, data));
      if (data['schemaVersion'] != 2) _queueMigration(uid, doc.id);
    }
    return HistoryPage(
      records: List.unmodifiable(records),
      cursor: documents.isEmpty ? null : documents.last,
      hasMore: snapshot.docs.length > pageSize,
    );
  }

  // Migrate only entries actually visited, one at a time, without delaying the
  // list. Read again transactionally so a concurrent delete cannot resurrect it.
  void _queueMigration(String uid, String id) {
    final key = '$uid/$id';
    if (!_queuedMigrations.add(key)) return;
    _migrations = _migrations.catchError((Object _) {}).then((_) async {
      try {
        final account = _account(uid),
            game = account.collection('games').doc(id);
        final detail = account.collection('gameDetails').doc(id);
        await _firestore.runTransaction<void>((tx) async {
          final current = await tx.get(game);
          if (!current.exists || current.data()?['schemaVersion'] == 2) return;
          final existingDetails = await tx.get(detail);
          final record = GameRecord.fromJson({...current.data()!, 'id': id});
          if (!existingDetails.exists) tx.set(detail, record.toJson());
          tx.set(game, GameSummary.fromRecord(record).toJson());
        });
      } catch (_) {
        // Legacy records remain readable offline; retry on the next visit.
      } finally {
        _queuedMigrations.remove(key);
      }
    });
    unawaited(_migrations);
  }

  Future<GameRecord?> getGame(String gameId) async {
    final uid = _uid;
    if (uid == null) return null;
    final account = _account(uid);
    final game = await account.collection('games').doc(gameId).get();
    if (!game.exists) return null;
    if (game.data()?['schemaVersion'] != 2) {
      return GameRecord.fromJson({...game.data()!, 'id': gameId});
    }
    final detail = await account.collection('gameDetails').doc(gameId).get();
    return detail.exists
        ? GameRecord.fromJson({...detail.data()!, 'id': gameId})
        : null;
  }

  Future<void> addGame(GameRecord game) async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to save a game.');
    final account = _account(uid), batch = _firestore.batch();
    batch.set(
      account.collection('games').doc(game.id),
      GameSummary.fromRecord(game).toJson(),
    );
    batch.set(account.collection('gameDetails').doc(game.id), game.toJson());
    await batch.commit();
  }

  Future<void> _deleteGames(String uid, Iterable<String> ids) async {
    final account = _account(uid), batch = _firestore.batch();
    for (final id in ids.toSet()) {
      await _deleteFinishedRoom(uid, id);
      // Retain aggregate deduplication with an opaque receipt, not game data.
      batch.set(
        account.collection('resultReceipts').doc(resultReceiptId(uid, id)),
        {'processed': true},
      );
      batch.delete(account.collection('games').doc(id));
      batch.delete(account.collection('gameDetails').doc(id));
      batch.delete(account.collection('gameResults').doc(id));
      batch.delete(account.collection('gameResultsV2').doc(id));
    }
    await batch.commit();
  }

  /// Firestore parent deletion does not cascade. Purge all legacy QR children
  /// while the parent still exists for host authorization; keep active rooms.
  Future<void> _deleteFinishedRoom(String uid, String gameId) async {
    final room = _firestore.collection('sessions').doc(gameId);
    final snapshot = await room.get(const GetOptions(source: Source.server));
    if (!snapshot.exists ||
        snapshot.data()?['hostUid'] != uid ||
        snapshot.data()?['status'] != 'finished') {
      return;
    }
    for (final name in [
      'hostState',
      'actionRequests',
      'joinRequests',
      'secrets',
      'seats',
      'members',
    ]) {
      while (true) {
        final page = await room
            .collection(name)
            .limit(100)
            .get(const GetOptions(source: Source.server));
        if (page.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    final batch = _firestore.batch();
    batch.delete(room);
    await batch.commit();
  }

  Future<void> deleteGame(String gameId) async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to delete a game.');
    await _deleteGames(uid, [gameId]);
  }

  Future<void> clearHistory() async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to delete history.');
    final account = _account(uid);
    // Three records keep all rule access checks inside the atomic write budget.
    // Include old orphaned reports/markers from versions predating full deletion.
    for (final name in [
      'games',
      'gameDetails',
      'gameResults',
      'gameResultsV2',
    ]) {
      while (true) {
        final page = await account
            .collection(name)
            .limit(3)
            .get(const GetOptions(source: Source.server));
        if (page.docs.isEmpty) break;
        await _deleteGames(uid, page.docs.map((doc) => doc.id));
      }
    }
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(),
);
