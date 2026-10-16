import 'package:game_core/src/entities/game_state.dart';
import 'package:game_core/src/events/game_event.dart';
import 'package:game_core/src/rules/game_ruleset.dart';
import 'package:game_core/src/errors/game_error.dart';
import 'package:game_core/src/enums/phase.dart';

class NightConflictException extends GameException {
  NightConflictException(super.message) : super(code: 'NIGHT_CONFLICT');
}

class NightResolutionEngine {
  static GameState resolve(
    GameState state,
    GameRuleset rules, {
    DateTime? timestamp,
  }) {
    if (state.eventHistory.any(
      (event) =>
          event.gameId == state.id &&
          event.round == state.round &&
          event.type == EventType.nightResolutionSummary,
    )) {
      return state;
    }
    final aliveIds = state.alivePlayers.map((player) => player.id).toSet();
    // 1. Get all events from this night
    final nightEvents = state.eventHistory
        .where(
          (e) =>
              e.gameId == state.id &&
              e.round == state.round &&
              e.phase.name.startsWith('night') &&
              e.phase != Phase.nightResolution &&
              aliveIds.contains(e.targetId),
        )
        .toList();

    // 2. Separate by type
    final assassinations = nightEvents
        .where((e) => e.type == EventType.assassination)
        .toList();
    final protections = nightEvents
        .where((e) => e.type == EventType.protection)
        .toList();
    final silences = nightEvents
        .where((e) => e.type == EventType.silence)
        .toList();

    // 3. Resolve conflicts for Assassinations
    final mafiaTargets = assassinations.map((e) => e.targetId!).toSet();
    if (mafiaTargets.length > 1 && !rules.allowMultipleAssassinationsPerNight) {
      throw NightConflictException(
        "Multiple different assassination targets found, but rules do not allow multiple assassinations.",
      );
    }

    // 4. Resolve Protections
    final protectedTargetIds = protections.map((e) => e.targetId!).toSet();

    // Sniper Kills
    final sniperKills = nightEvents
        .where((e) => e.type == EventType.sniperKill)
        .toList();

    // 5. Calculate deaths
    final mafiaDeadIds = <String>{};
    final sniperDeadIds = <String>{};
    final protectedFromMafiaIds = <String>{};
    final protectedFromSniperIds = <String>{};

    // Separate mafia targets and sniper targets
    final sniperTargets = sniperKills.map((e) => e.targetId!).toSet();

    for (var targetId in mafiaTargets) {
      if (protectedTargetIds.contains(targetId)) {
        protectedFromMafiaIds.add(targetId);
      } else {
        mafiaDeadIds.add(targetId);
      }
    }

    for (var targetId in sniperTargets) {
      if (protectedTargetIds.contains(targetId)) {
        protectedFromSniperIds.add(targetId);
      } else {
        sniperDeadIds.add(targetId);
      }
    }

    final deadPlayerIds = {...mafiaDeadIds, ...sniperDeadIds};

    // 6. Calculate silences
    final silencedPlayerIds = silences.map((e) => e.targetId!).toSet()
      ..removeAll(deadPlayerIds);

    // 7. Update players
    final updatedPlayers = state.players.map((p) {
      bool isAlive = p.isAlive;
      bool isSilenced = silencedPlayerIds.contains(p.id);

      if (deadPlayerIds.contains(p.id)) {
        isAlive = false;
      }

      if (!isAlive) {
        isSilenced = false;
      }

      return p.copyWith(isAlive: isAlive, isSilenced: isSilenced);
    }).toList();

    // 8. Create resolution event
    final resolutionEvent = GameEvent(
      id: 'res_${state.id}_${state.round}',
      gameId: state.id,
      round: state.round,
      phase: Phase.nightResolution,
      type: EventType.nightResolutionSummary,
      timestamp: timestamp ?? DateTime.now(),
      metadata: {
        'assassinatedIds': deadPlayerIds.toList(),
        'mafiaDeadIds': mafiaDeadIds.toList(),
        'sniperDeadIds': sniperDeadIds.toList(),
        'protectedIds': protectedTargetIds.toList(),
        'silencedIds': silencedPlayerIds.toList(),
        'protectedFromMafiaIds': protectedFromMafiaIds.toList(),
        'protectedFromSniperIds': protectedFromSniperIds.toList(),
        'successfulProtections': {
          ...protectedFromMafiaIds,
          ...protectedFromSniperIds,
        }.toList(),
      },
    );

    return state.copyWith(
      players: updatedPlayers,
      eventHistory: [...state.eventHistory, resolutionEvent],
    );
  }
}
