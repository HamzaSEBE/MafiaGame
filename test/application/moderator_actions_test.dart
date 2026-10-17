import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_core/game_core.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import '../support/memory_firestore.dart';

GameState match({Phase phase = Phase.day, int round = 2}) => GameState(
  id: 'room',
  phase: phase,
  round: round,
  initialMafiaCount: 1,
  discussionRemainingSeconds: 120,
  discussionPaused: true,
  players: [
    for (var i = 0; i < 5; i++)
      Player(
        id: 'p$i',
        name: 'لاعب $i',
        role: i == 0 ? Role.mafiaSheikh : Role.goodCitizen,
        createdAt: DateTime(2026),
      ),
  ],
);

void main() {
  test(
    'undo restores phase and casualties, excludes clock changes, pauses restored day',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final control = container.read(gameOrchestratorProvider.notifier);
      control.restoreCheckpoint(match());
      control.updateDiscussionClock(90, paused: false);
      expect(control.canUndo, false);
      control.startVoting();
      control.kickPlayer('p1');
      expect(
        container.read(gameOrchestratorProvider).getPlayerById('p1')!.isKicked,
        true,
      );
      control.undoStep();
      expect(
        container.read(gameOrchestratorProvider).getPlayerById('p1')!.isAlive,
        true,
      );
      control.undoStep();
      final day = container.read(gameOrchestratorProvider);
      expect(day.phase, Phase.day);
      expect(day.discussionPaused, true);
      expect(day.discussionDeadlineAt, isNull);
    },
  );
  test(
    'kick is not a vote execution or Citizen Boy retaliation and rechecks parity',
    () {
      final g = GameMachine(match());
      g.state = g.state.copyWith(
        players: [
          g.state.players[0],
          g.state.players[1].copyWith(role: Role.citizensBoy),
          g.state.players[2],
        ],
      );
      g.kickPlayer('p1');
      expect(g.state.phase, Phase.winCheck);
      expect(g.state.winner, Team.mafia);
      expect(CitizenBoyEngine.pendingActor(g.state), isNull);
      expect(g.state.correctMafiaExecutionsCount, 0);
      expect(g.state.eventHistory.single.type, EventType.playerKicked);
    },
  );
  test(
    'kick cancels unresolved night actions involving the removed player',
    () {
      final g = GameMachine(match(phase: Phase.night));
      g.submitNightAction(
        actorId: 'p0',
        targetId: 'p1',
        type: EventType.assassination,
      );
      g.kickPlayer('p1');
      expect(
        g.state.eventHistory.where((e) => e.type == EventType.assassination),
        isEmpty,
      );
      expect(
        InteractivePrompts.night(g.state)['p0']!.first.availableTargets,
        isNot(contains('p1')),
      );
    },
  );
  test(
    'rematch gets a new result identity, keeps roster IDs/names/rules, resets all abilities',
    () {
      final old = match().copyWith(
        phase: Phase.winCheck,
        winner: Team.citizens,
        players: [
          for (final p in match().players)
            p.copyWith(
              isAlive: false,
              isKicked: p.id == 'p4',
              isSilenced: true,
              isCitizenSheikhRevealed: true,
            ),
        ],
      );
      final g = GameMachine(old);
      g.prepareRematch();
      expect(g.state.id, isNot(old.id));
      expect(g.state.players.map((p) => p.id), ['p0', 'p1', 'p2', 'p3']);
      expect(
        g.state.players.map((p) => p.name),
        old.players.take(4).map((p) => p.name),
      );
      expect(g.state.rules.toJson(), old.rules.toJson());
      expect(
        g.state.players.every(
          (p) =>
              p.isAlive &&
              !p.isSilenced &&
              !p.isCitizenSheikhRevealed &&
              !p.hasSniper,
        ),
        true,
      );
      expect(g.state.eventHistory, isEmpty);
      expect(g.state.winner, isNull);
      expect(g.state.round, 1);
    },
  );

  test('a batch of host changes is a single undo step', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final g = c.read(gameOrchestratorProvider.notifier);
    g.restoreCheckpoint(match(phase: Phase.night));
    g.beginModeratorStep();
    g.submitNightAction(
      actorId: 'p0',
      targetId: 'p1',
      type: EventType.assassination,
    );
    g.resolveNight();
    g.commitModeratorStep();
    expect(
      c.read(gameOrchestratorProvider).getPlayerById('p1')!.isAlive,
      false,
    );
    final restored = g.undoStep();
    expect(restored.phase, Phase.night);
    expect(restored.eventHistory, isEmpty);
    expect(restored.alivePlayers.length, 5);
    expect(g.canUndo, false);
  });
  late MemoryFirestore db;
  late InteractiveService service;
  void seed({bool finished = false, bool closed = false}) {
    db = MemoryFirestore();
    service = InteractiveService(firestore: db, auth: MemoryAuth('host'));
    addTearDown(service.dispose);
    final state = match(round: 4).copyWith(
      phase: finished ? Phase.winCheck : Phase.day,
      winner: finished ? Team.citizens : null,
    );
    db.documents['sessions/room'] = {
      'id': 'room',
      'hostUid': 'host',
      'status': finished ? 'finished' : 'active',
      'closed': closed,
      'phase': state.phase.name,
      'round': 4,
      'stateVersion': 7,
      'actionRevision': 9,
      'matchId': 'room',
      'createdAt': Timestamp.fromDate(DateTime(2026)),
    };
    db.documents['sessions/room/hostState/current'] = {
      'schemaVersion': 1,
      'state': state.toJson(),
    };
    for (final p in state.players) {
      db.documents['sessions/room/seats/${p.id}'] = {
        'id': p.id,
        'linkedUid': 'u${p.id}',
        'isAlive': true,
      };
      db.documents['sessions/room/members/u${p.id}'] = {
        'uid': 'u${p.id}',
        'seatId': p.id,
      };
      db.documents['sessions/room/secrets/${p.id}'] = {
        'privateResult': 'old result',
      };
    }
  }

  test(
    'QR rewind permits earlier round only explicitly, invalidates old actions and private results',
    () async {
      seed();
      final old = match(phase: Phase.voting, round: 3);
      await expectLater(
        service.syncGameState('room', old, null, null),
        throwsStateError,
      );
      await service.syncGameState(
        'room',
        old,
        null,
        null,
        moderatorRewind: true,
        actionPrompts: InteractivePrompts.voting(old),
      );
      expect(db.documents['sessions/room']!['round'], 3);
      expect(db.documents['sessions/room']!['actionRevision'], 10);
      expect(db.documents['sessions/room']!['stateVersion'], 8);
      final secret = db.documents['sessions/room/secrets/p1']!;
      expect(secret['promptRevision'], 10);
      expect(secret['privateResult'], isNull);
      expect((secret['requiredActions'] as List).first['type'], 'vote');
    },
  );
  test(
    'QR rematch changes game but preserves membership and linked seats atomically',
    () async {
      seed(finished: true);
      final g = GameMachine(
        match().copyWith(phase: Phase.winCheck, winner: Team.citizens),
      );
      g.prepareRematch();
      expect(g.assignRoles({Role.mafiaSheikh: 1, Role.goodCitizen: 4}), isNull);
      await service.syncGameState('room', g.state, null, null, isRematch: true);
      expect(db.documents['sessions/room']!['matchId'], g.state.id);
      expect(db.documents['sessions/room']!['status'], 'active');
      expect(db.documents['sessions/room']!['round'], 1);
      expect(db.documents['sessions/room']!['actionRevision'], 10);
      expect(db.documents['sessions/room/seats/p1']!['linkedUid'], 'up1');
      expect(db.documents['sessions/room/members/up1']!['seatId'], 'p1');
      expect(
        db.documents['sessions/room/secrets/p1']!['privateResult'],
        isNull,
      );
      expect(db.commits.single, contains('sessions/room/hostState/current'));
    },
  );

  test(
    'rematch retry after lost acknowledgement never creates another match',
    () async {
      seed(finished: true);
      final g = GameMachine(
        match().copyWith(phase: Phase.winCheck, winner: Team.citizens),
      );
      g.prepareRematch();
      g.assignRoles({Role.mafiaSheikh: 1, Role.goodCitizen: 4});
      await service.syncGameState('room', g.state, null, null, isRematch: true);
      await service.syncGameState('room', g.state, null, null, isRematch: true);
      expect(db.documents['sessions/room']!['actionRevision'], 10);
      expect(db.documents['sessions/room']!['stateVersion'], 8);
    },
  );
  test('manually closed room can never restart', () async {
    seed(finished: true, closed: true);
    final g = GameMachine(
      match().copyWith(phase: Phase.winCheck, winner: Team.citizens),
    );
    g.prepareRematch();
    g.assignRoles({Role.mafiaSheikh: 1, Role.goodCitizen: 4});
    await expectLater(
      service.syncGameState('room', g.state, null, null, isRematch: true),
      throwsStateError,
    );
  });
}
