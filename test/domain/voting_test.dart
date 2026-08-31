import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/domain/engine/voting_engine.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';

void main() {
  group('Voting Engine Tests', () {
    late GameState state;

    setUp(() {
      state = GameState(
        id: 'test_game',
        phase: Phase.voteResolution,
        round: 1,
        players: [
          Player(id: 'A', name: 'Player A', role: Role.goodCitizen, createdAt: DateTime.now()),
          Player(id: 'B', name: 'Player B', role: Role.goodCitizen, createdAt: DateTime.now()),
          Player(id: 'C', name: 'Player C', role: Role.goodCitizen, createdAt: DateTime.now()),
        ],
        eventHistory: [],
      );
    });

    test('Clear winner', () {
      final stateWithEvents = state.copyWith(
        eventHistory: [
          GameEvent(id: 'v1', gameId: 'test_game', round: 1, phase: Phase.voting, type: EventType.vote, actorId: 'A', targetId: 'B', timestamp: DateTime.now()),
          GameEvent(id: 'v2', gameId: 'test_game', round: 1, phase: Phase.voting, type: EventType.vote, actorId: 'B', targetId: 'A', timestamp: DateTime.now()),
          GameEvent(id: 'v3', gameId: 'test_game', round: 1, phase: Phase.voting, type: EventType.vote, actorId: 'C', targetId: 'B', timestamp: DateTime.now()),
        ]
      );

      final result = VotingEngine.calculateVotes(stateWithEvents);
      expect(result.isTie, isFalse);
      expect(result.eliminatedPlayerId, equals('B'));
    });

    test('Tie', () {
      final stateWithEvents = state.copyWith(
        eventHistory: [
          GameEvent(id: 'v1', gameId: 'test_game', round: 1, phase: Phase.voting, type: EventType.vote, actorId: 'A', targetId: 'B', timestamp: DateTime.now()),
          GameEvent(id: 'v2', gameId: 'test_game', round: 1, phase: Phase.voting, type: EventType.vote, actorId: 'B', targetId: 'A', timestamp: DateTime.now()),
        ]
      );

      final result = VotingEngine.calculateVotes(stateWithEvents);
      expect(result.isTie, isTrue);
      expect(result.eliminatedPlayerId, isNull);
    });
  });
}
