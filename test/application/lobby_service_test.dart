import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import '../support/memory_firestore.dart';

void main() {
  late MemoryFirestore db;
  late InteractiveService service;
  setUp(() {
    db = MemoryFirestore();
    service = InteractiveService(firestore: db, auth: MemoryAuth('host'));
  });
  tearDown(() => service.dispose());
  void seed(String seat, String guest) {
    db.documents['sessions/room'] = {
      'id': 'room',
      'hostUid': 'host',
      'status': 'waiting',
      'phase': 'roleReveal',
      'createdAt': Timestamp.fromDate(DateTime(2026)),
    };
    db.documents['sessions/room/seats/$seat'] = {
      'id': seat,
      'linkedUid': null,
      'status': 'unlinked',
    };
    db.documents['sessions/room/joinRequests/$guest'] = {
      'seatId': seat,
      'uid': guest,
    };
  }

  test(
    'all four approval reads start together; duplicate taps commit once',
    () async {
      seed('a', 'guest');
      final gate = Completer<void>();
      db.beforeDocumentRead = (_) => gate.future;
      final attempts = List.generate(
        10,
        (_) => service.approveJoinRequest('room', 'a', 'guest'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(db.reads.length, 4);
      expect(db.commits, isEmpty);
      gate.complete();
      await Future.wait(attempts);
      expect(db.commits.length, 1);
      expect(db.documents['sessions/room/seats/a']!['linkedUid'], 'guest');
      expect(db.documents['sessions/room/members/guest'], {
        'uid': 'guest',
        'seatId': 'a',
      });
      expect(
        db.documents.containsKey('sessions/room/joinRequests/guest'),
        false,
      );
      await service.approveJoinRequest('room', 'a', 'guest');
      expect(
        db.commits.length,
        1,
      ); // Idempotent confirmation after a delayed response.
    },
  );
  test('approvals for independent seats proceed concurrently', () async {
    seed('a', 'one');
    seed('b', 'two');
    final gate = Completer<void>();
    db.beforeDocumentRead = (_) => gate.future;
    final one = service.approveJoinRequest('room', 'a', 'one');
    final two = service.approveJoinRequest('room', 'b', 'two');
    await Future<void>.delayed(Duration.zero);
    expect(db.reads.length, 8);
    gate.complete();
    await Future.wait([one, two]);
    expect(db.documents['sessions/room/members/one']!['seatId'], 'a');
    expect(db.documents['sessions/room/members/two']!['seatId'], 'b');
  });
  test('failed commit retains request and releases retry guard', () async {
    seed('a', 'guest');
    db.failCommit = true;
    await expectLater(
      service.approveJoinRequest('room', 'a', 'guest'),
      throwsStateError,
    );
    expect(db.documents['sessions/room/seats/a']!['linkedUid'], isNull);
    expect(db.documents.containsKey('sessions/room/joinRequests/guest'), true);
    db.failCommit = false;
    await service.approveJoinRequest('room', 'a', 'guest');
    expect(db.documents['sessions/room/seats/a']!['linkedUid'], 'guest');
  });
  test('stale request and occupied seat cannot be approved', () async {
    seed('a', 'guest');
    db.documents['sessions/room/joinRequests/guest']!['seatId'] = 'b';
    await expectLater(
      service.approveJoinRequest('room', 'a', 'guest'),
      throwsStateError,
    );
    db.documents['sessions/room/joinRequests/guest']!['seatId'] = 'a';
    db.documents['sessions/room/seats/a']!['linkedUid'] = 'other';
    await expectLater(
      service.approveJoinRequest('room', 'a', 'guest'),
      throwsStateError,
    );
    expect(db.commits, isEmpty);
  });
  test(
    'new room creation avoids extra get; existing room is read and preserved',
    () async {
      final state = GameState(
        id: 'new',
        phase: Phase.roleReveal,
        players: [
          Player(
            id: 'p',
            name: 'Player',
            role: Role.goodCitizen,
            createdAt: DateTime(2026),
          ),
        ],
      );
      expect(await service.createSession(state), 'new');
      expect(db.reads, ['sessions/new']);
      db.documents['sessions/new']!['createdAt'] = Timestamp.fromDate(
        DateTime(2026),
      );
      db.documents['sessions/new']!['stateVersion'] = 8;
      db.documents['sessions/new/seats/p']!['linkedUid'] = 'old-member';
      db.reads.clear();
      await service.createSession(state);
      expect(db.reads, ['sessions/new', 'sessions/new']);
      expect(db.documents['sessions/new/seats/p']!['linkedUid'], 'old-member');
      expect((await service.getSession('new'))!.stateVersion, 8);
    },
  );
}
