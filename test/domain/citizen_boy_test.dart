import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/domain/engine/citizen_boy_engine.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';

void main() {
  group('Citizen Boy Engine Tests', () {
    late GameState state;

    setUp(() {
      state = GameState(
        id: 'test_game',
        phase: Phase.triggeredAbility,
        round: 1,
        players: [
          Player(id: 'CB', name: 'Citizen Boy', role: Role.citizensBoy, isAlive: false, createdAt: DateTime.now()),
          Player(id: 'A', name: 'Player A', role: Role.goodCitizen, createdAt: DateTime.now()),
          Player(id: 'B', name: 'Mafia', role: Role.normalMafia, createdAt: DateTime.now()),
        ],
        eventHistory: [],
      );
    });

    test('Should trigger when Citizen Boy dies', () {
      final shouldTrigger = CitizenBoyEngine.shouldTriggerAbility(state, 'CB');
      expect(shouldTrigger, isTrue);
    });

    test('Boy chooses any alive player => target eliminated', () {
      final newState = CitizenBoyEngine.applyRetaliation(state, 'CB', 'B');
      
      final playerB = newState.getPlayerById('B');
      expect(playerB!.isAlive, isFalse);
      
      final retaliationEvent = newState.eventHistory.firstWhere((e) => e.type == EventType.citizenBoyRetaliation);
      expect(retaliationEvent.actorId, equals('CB'));
      expect(retaliationEvent.targetId, equals('B'));
    });
  });
}
