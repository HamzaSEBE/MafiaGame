import 'package:game_core/src/entities/game_state.dart';
import 'package:game_core/src/entities/player.dart';
import 'package:game_core/src/errors/game_error.dart';
import 'package:game_core/src/enums/phase.dart';
import 'package:game_core/src/enums/role.dart';
import 'package:game_core/src/events/game_event.dart';

class CitizenBoyEngine {
  /// Check if the recently deceased player is the Citizen Boy.
  /// If so, we need to transition to the triggered ability phase.
  static bool shouldTriggerAbility(GameState state, String recentlyDeceasedId) {
    final player = state.getPlayerById(recentlyDeceasedId);
    if (player == null || player.isKicked) return false;

    // Trigger only if it's the citizen boy and he is now dead
    if (player.role == Role.citizensBoy && !player.isAlive) {
      // Also ensure we haven't already used his ability
      final alreadyUsed = state.eventHistory.any(
        (e) =>
            e.gameId == state.id &&
            e.type == EventType.citizenBoyRetaliation &&
            e.actorId == player.id,
      );
      return !alreadyUsed;
    }
    return false;
  }

  /// Resolve the actor from the latest death, including nights with two victims.
  static Player? pendingActor(GameState state) {
    for (final event in state.eventHistory.reversed) {
      if (event.gameId != state.id || event.round != state.round) continue;
      final List<String> deceasedIds;
      if (event.type == EventType.nightResolutionSummary) {
        deceasedIds =
            (event.metadata['assassinatedIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [];
      } else if (event.type == EventType.elimination ||
          event.type == EventType.citizenBoyRetaliation) {
        deceasedIds = [if (event.targetId != null) event.targetId!];
      } else {
        continue;
      }
      for (final id in deceasedIds) {
        if (shouldTriggerAbility(state, id)) return state.getPlayerById(id);
      }
      return null;
    }
    return null;
  }

  /// Apply the retaliation kill
  static GameState applyRetaliation(
    GameState state,
    String citizenBoyId,
    String targetId, {
    DateTime? timestamp,
  }) {
    if (state.eventHistory.any(
      (event) =>
          event.gameId == state.id &&
          event.type == EventType.citizenBoyRetaliation &&
          event.actorId == citizenBoyId,
    )) {
      return state;
    }
    if (state.phase != Phase.triggeredAbility) {
      throw WrongPhaseException('Not in triggered ability phase');
    }
    if (!shouldTriggerAbility(state, citizenBoyId)) {
      throw RoleCannotActException('Only a deceased Citizen Boy can retaliate');
    }
    final target = state.getPlayerById(targetId);
    if (target == null || !target.isAlive || targetId == citizenBoyId) {
      throw InvalidTargetException('Retaliation requires a living target');
    }
    final updatedPlayers = state.players.map((p) {
      if (p.id == targetId) {
        return p.copyWith(isAlive: false, isSilenced: false);
      }
      return p;
    }).toList();

    final retaliationEvent = GameEvent(
      id: 'ret_${state.id}_$citizenBoyId',
      gameId: state.id,
      round: state.round,
      phase: Phase.triggeredAbility,
      type: EventType.citizenBoyRetaliation,
      actorId: citizenBoyId,
      targetId: targetId,
      timestamp: timestamp ?? DateTime.now(),
    );

    return state.copyWith(
      players: updatedPlayers,
      eventHistory: [...state.eventHistory, retaliationEvent],
    );
  }
}
