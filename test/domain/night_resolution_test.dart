import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/domain/engine/night_resolution_engine.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';

void main() {
  group('Night Resolution Engine Tests', () {
    late GameState state;

    setUp(() {
      state = GameState(
        id: 'test_game',
        phase: Phase.nightResolution,
        round: 1,
        players: [
          Player(id: 'A', name: 'Citizen A', role: Role.goodCitizen, createdAt: DateTime.now()),
          Player(id: 'B', name: 'Citizen B', role: Role.goodCitizen, createdAt: DateTime.now()),
        ],
        eventHistory: [],
      );
    });

    test('Protection: Kill A Protect A => A survives', () {
      final stateWithEvents = state.copyWith(
        eventHistory: [
          GameEvent(
            id: 'e1', gameId: 'test_game', round: 1, phase: Phase.nightMafiaSheikh, 
            type: EventType.assassination, targetId: 'A', timestamp: DateTime.now()
          ),
          GameEvent(
            id: 'e2', gameId: 'test_game', round: 1, phase: Phase.nightCitizensGirl, 
            type: EventType.protection, targetId: 'A', timestamp: DateTime.now()
          ),
        ]
      );

      final resultState = NightResolutionEngine.resolve(stateWithEvents, const GameRuleset());
      final playerA = resultState.getPlayerById('A');
      expect(playerA!.isAlive, isTrue);
    });

    test('No protection: Kill A Protect B => A dies', () {
      final stateWithEvents = state.copyWith(
        eventHistory: [
          GameEvent(
            id: 'e1', gameId: 'test_game', round: 1, phase: Phase.nightMafiaSheikh, 
            type: EventType.assassination, targetId: 'A', timestamp: DateTime.now()
          ),
          GameEvent(
            id: 'e2', gameId: 'test_game', round: 1, phase: Phase.nightCitizensGirl, 
            type: EventType.protection, targetId: 'B', timestamp: DateTime.now()
          ),
        ]
      );

      final resultState = NightResolutionEngine.resolve(stateWithEvents, const GameRuleset());
      final playerA = resultState.getPlayerById('A');
      final playerB = resultState.getPlayerById('B');
      
      expect(playerA!.isAlive, isFalse);
      expect(playerB!.isAlive, isTrue);
    });
  });
}
