import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';

class CitizenBoyEngine {
  /// Check if the recently deceased player is the Citizen Boy.
  /// If so, we need to transition to the triggered ability phase.
  static bool shouldTriggerAbility(GameState state, String recentlyDeceasedId) {
    final player = state.getPlayerById(recentlyDeceasedId);
    if (player == null) return false;

    // Trigger only if it's the citizen boy and he is now dead
    if (player.role == Role.citizensBoy && !player.isAlive) {
      // Also ensure we haven't already used his ability
      final alreadyUsed = state.eventHistory.any((e) => 
        e.type == EventType.citizenBoyRetaliation && e.actorId == player.id
      );
      return !alreadyUsed;
    }
    return false;
  }

  /// Apply the retaliation kill
  static GameState applyRetaliation(GameState state, String citizenBoyId, String targetId) {
    final updatedPlayers = state.players.map((p) {
      if (p.id == targetId) {
        return p.copyWith(isAlive: false);
      }
      return p;
    }).toList();

    final retaliationEvent = GameEvent(
      id: 'ret_${DateTime.now().millisecondsSinceEpoch}',
      gameId: state.id,
      round: state.round,
      phase: Phase.triggeredAbility,
      type: EventType.citizenBoyRetaliation,
      actorId: citizenBoyId,
      targetId: targetId,
      timestamp: DateTime.now(),
    );

    return state.copyWith(
      players: updatedPlayers,
      eventHistory: [...state.eventHistory, retaliationEvent],
    );
  }
}
