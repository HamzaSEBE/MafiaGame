import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

void main() {
  final at = DateTime.utc(2026, 10, 10);
  final players = [
    Player(id: 'm', name: 'Mafia', role: Role.mafiaSheikh, createdAt: at),
    Player(id: 'd1', name: 'Doctor1', role: Role.citizensGirl, createdAt: at),
    Player(id: 'd2', name: 'Doctor2', role: Role.citizensGirl, createdAt: at),
    Player(
      id: 'i1',
      name: 'Inspector1',
      role: Role.citizensSheikh,
      createdAt: at,
    ),
    Player(
      id: 'i2',
      name: 'Inspector2',
      role: Role.citizensSheikh,
      createdAt: at,
    ),
    Player(id: 'c', name: 'Citizen', role: Role.goodCitizen, createdAt: at),
  ];
  test(
    'all doctors and investigators have shared local and remote eligibility',
    () {
      final state = GameState(
        id: 'g',
        phase: Phase.night,
        round: 2,
        players: players,
      );
      final prompts = InteractivePrompts.night(state);
      for (final id in ['d1', 'd2']) {
        expect(prompts[id]!.single.type, 'protection');
      }
      for (final id in ['i1', 'i2']) {
        expect(prompts[id]!.single.type, 'investigation');
      }
    },
  );
  test('server reduction is deterministic and matches local game machine', () {
    final state = GameState(
      id: 'g',
      phase: Phase.night,
      round: 2,
      players: players,
      initialMafiaCount: 1,
    );
    final actions = [
      {'seatId': 'm', 'actionType': 'assassination', 'targetId': 'c'},
      {'seatId': 'd2', 'actionType': 'protection', 'targetId': 'c'},
    ];
    final result = ServerReducer.transition(
      state,
      'closeNight',
      actions,
      at,
      'cmd',
    );
    final repeat = ServerReducer.transition(
      state,
      'closeNight',
      actions,
      at,
      'cmd',
    );
    expect(result.toJson(), repeat.toJson());
    var sequence = 0;
    final local = GameMachine(
      state,
      clock: () => at,
      nextId: () => 'cmd:${sequence++}',
    );
    // Stable ordering follows actor/type in the server adapter.
    local.submitNightAction(
      actorId: 'd2',
      targetId: 'c',
      type: EventType.protection,
    );
    local.submitNightAction(
      actorId: 'm',
      targetId: 'c',
      type: EventType.assassination,
    );
    local.resolveNight();
    expect(result.toJson(), local.state.toJson());
    expect(result.getPlayerById('c')!.isAlive, true);
  });
  test('invalid phase and target cannot become events', () {
    final state = GameState(
      id: 'g',
      phase: Phase.day,
      round: 2,
      players: players,
    );
    expect(
      () => ServerReducer.transition(state, 'closeNight', [], at, 'cmd'),
      throwsStateError,
    );
    expect(
      () => ServerReducer.transition(
        state.copyWith(phase: Phase.night),
        'closeNight',
        [
          {'seatId': 'm', 'actionType': 'assassination', 'targetId': 'm'},
        ],
        at,
        'cmd',
      ),
      throwsStateError,
    );
    expect(state.eventHistory, isEmpty);
  });
  test(
    'snapshots detect same game changes and nullable winners can be cleared',
    () {
      final state = GameState(
        id: 'g',
        players: players,
        winner: Team.mafia,
        victoryReason: 'win',
      );
      final updated = state.copyWith(
        phase: Phase.day,
        winner: null,
        victoryReason: null,
      );
      expect(updated == state, false);
      expect(updated.winner, isNull);
      expect(updated.victoryReason, isNull);
      expect(() => updated.players.add(players.first), throwsUnsupportedError);
    },
  );
  test('discussion deadline survives restore and pauses without drift', () {
    final machine = GameMachine(
      GameState(id: 'clock', phase: Phase.day, players: players),
      clock: () => at,
    );
    machine.updateDiscussionClock(90, paused: false);
    final restored = GameState.fromJson(machine.state.toJson());
    expect(restored.discussionDeadlineAt, at.add(const Duration(seconds: 90)));
    expect(restored.discussionPaused, false);
    machine.updateDiscussionClock(42, paused: true);
    final paused = GameState.fromJson(machine.state.toJson());
    expect(paused.discussionDeadlineAt, isNull);
    expect(paused.discussionRemainingSeconds, 42);
    expect(paused.discussionPaused, true);
    expect(
      () => machine.updateDiscussionClock(7201, paused: false),
      throwsStateError,
    );
    machine.startVoting();
    expect(machine.state.discussionDeadlineAt, isNull);
    expect(
      () => machine.updateDiscussionClock(10, paused: false),
      throwsStateError,
    );
  });
}
