import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';
import 'package:mafia_nightfall/core/error/game_error.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';

class NightConflictException extends GameException {
  NightConflictException(String message) : super(message, code: 'NIGHT_CONFLICT');
}

class NightResolutionEngine {
  static GameState resolve(GameState state, GameRuleset rules) {
    // 1. Get all events from this night
    final nightEvents = state.eventHistory.where((e) => 
      e.round == state.round && 
      e.phase.name.startsWith('night') && 
      e.phase != Phase.nightResolution
    ).toList();

    // 2. Separate by type
    final assassinations = nightEvents.where((e) => e.type == EventType.assassination).toList();
    final protections = nightEvents.where((e) => e.type == EventType.protection).toList();
    final silences = nightEvents.where((e) => e.type == EventType.silence).toList();

    // 3. Resolve conflicts for Assassinations
    List<String> finalAssassinationTargets = [];
    if (assassinations.isNotEmpty) {
      final uniqueTargets = assassinations.map((e) => e.targetId!).toSet().toList();
      
      if (uniqueTargets.length > 1) {
        if (!rules.allowMultipleAssassinationsPerNight) {
          throw NightConflictException("Multiple different assassination targets found, but rules do not allow multiple assassinations.");
        } else {
          finalAssassinationTargets = uniqueTargets;
        }
      } else {
        finalAssassinationTargets = uniqueTargets;
      }
    }

    // 4. Resolve Protections
    final protectedTargetIds = protections.map((e) => e.targetId!).toSet();

    // 5. Calculate deaths
    final deadPlayerIds = <String>{};
    for (var targetId in finalAssassinationTargets) {
      if (!protectedTargetIds.contains(targetId)) {
        deadPlayerIds.add(targetId);
      }
    }

    // 6. Calculate silences
    final silencedPlayerIds = silences.map((e) => e.targetId!).toSet();

    // 7. Update players
    final updatedPlayers = state.players.map((p) {
      bool isAlive = p.isAlive;
      bool isSilenced = silencedPlayerIds.contains(p.id);

      if (deadPlayerIds.contains(p.id)) {
        isAlive = false;
      }

      // If a player died, they shouldn't be silenced (or it doesn't matter, but let's clear it)
      if (!isAlive) {
        isSilenced = false;
      }

      // If they were already silenced from previous rounds, clear it unless re-silenced.
      // Wait, silence applies for the NEXT day. So anyone targeted by silence tonight is silenced tomorrow.
      
      return p.copyWith(
        isAlive: isAlive,
        isSilenced: isSilenced,
      );
    }).toList();

    // 8. Create resolution event
    final resolutionEvent = GameEvent(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      gameId: state.id,
      round: state.round,
      phase: Phase.nightResolution,
      type: EventType.nightResolutionSummary,
      timestamp: DateTime.now(),
      metadata: {
        'assassinatedIds': deadPlayerIds.toList(),
        'protectedIds': protectedTargetIds.toList(),
        'silencedIds': silencedPlayerIds.toList(),
        'successfulProtections': finalAssassinationTargets.where((t) => protectedTargetIds.contains(t)).toList(),
      },
    );

    return state.copyWith(
      players: updatedPlayers,
      eventHistory: [...state.eventHistory, resolutionEvent],
    );
  }
}
