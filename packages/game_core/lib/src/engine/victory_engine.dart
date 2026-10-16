import 'package:game_core/src/entities/game_state.dart';
import 'package:game_core/src/enums/role.dart';
import 'package:game_core/src/events/game_event.dart';
import 'package:game_core/src/rules/game_ruleset.dart';

enum VictoryStatus { mafiaWin, citizensWin, jokerWin, continueGame }

class VictoryEngine {
  static VictoryStatus evaluate(GameState state) {
    // 0. Check if Joker was just voted out
    if (state.eventHistory.isNotEmpty) {
      final lastEvent = state.eventHistory.last;
      if (lastEvent.gameId == state.id &&
          lastEvent.type == EventType.elimination &&
          lastEvent.targetId != null) {
        final eliminatedPlayer = state.getPlayerById(lastEvent.targetId!);
        if (eliminatedPlayer?.role == Role.joker) {
          return VictoryStatus.jokerWin;
        }
      }
    }

    final alivePlayers = state.alivePlayers;

    int mafiaCount = 0;
    int aliveCitizensCount = 0;

    for (var player in alivePlayers) {
      if (player.role.team == Team.mafia) {
        mafiaCount++;
      } else if (player.role.team == Team.citizens) {
        aliveCitizensCount++;
      }
    }

    final vRules = state.rules.victoryRules;

    // The execution target must remain achievable. Previously this mode could
    // continue forever, even with no living citizens or no remaining mafia.
    if (vRules.mode == VictoryMode.exactMafiaExecutions) {
      if (state.correctMafiaExecutionsCount >=
          vRules.requiredCorrectExecutions) {
        return VictoryStatus.citizensWin;
      }
      if (state.correctMafiaExecutionsCount + mafiaCount <
          vRules.requiredCorrectExecutions) {
        return VictoryStatus.mafiaWin;
      }
    }

    // RULE: Initial Mafia Count Parity (Equal Count Victory)
    if (vRules.mode == VictoryMode.equalCount) {
      if (mafiaCount == 0) {
        return VictoryStatus.citizensWin;
      }
      if (aliveCitizensCount <= state.initialMafiaCount) {
        return VictoryStatus.mafiaWin;
      }
      return VictoryStatus.continueGame;
    }

    // RULE: Classic Victory
    if (vRules.mode == VictoryMode.classic ||
        vRules.mode == VictoryMode.exactMafiaExecutions) {
      // If all mafia are dead, citizens win immediately
      if (mafiaCount == 0) {
        return VictoryStatus.citizensWin;
      }

      // Classic parity compares the two factions, not independent roles.
      // Keep the custom execution mode's existing fallback count.
      final opposingCount = vRules.mode == VictoryMode.classic
          ? aliveCitizensCount
          : alivePlayers.length - mafiaCount;
      if (opposingCount > mafiaCount) return VictoryStatus.continueGame;
      if (vRules.mode == VictoryMode.classic && mafiaCount > opposingCount) {
        return VictoryStatus.mafiaWin;
      }
      bool hasUnusedSniper = false;
      bool hasDoctorThatCanProtect = false;

      final pLimit = state.rules.abilityRules.protectionTargetLimit;

      // Build once instead of rescanning the entire history for every doctor
      // and every possible target (O(history + players²), formerly O(P²H)).
      final sniperActors = <String>{};
      final protectionCounts = <String, Map<String, int>>{};
      for (final event in state.eventHistory) {
        if (event.gameId != state.id || event.actorId == null) continue;
        if (event.type == EventType.sniperKill) {
          sniperActors.add(event.actorId!);
        } else if (event.type == EventType.protection &&
            event.targetId != null) {
          final counts = protectionCounts.putIfAbsent(event.actorId!, () => {});
          counts.update(
            event.targetId!,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }

      for (var p in alivePlayers) {
        if (p.role.team == Team.citizens) {
          if (state.rules.abilityRules.sniper &&
              p.hasSniper &&
              !sniperActors.contains(p.id)) {
            hasUnusedSniper = true;
          }
          if (p.role == Role.citizensGirl) {
            // Protection legally allows any living target, including herself.
            // Use the same per-target history and limit as RuleValidator.
            for (var target in alivePlayers) {
              final used = protectionCounts[p.id]?[target.id] ?? 0;
              if (pLimit == -1 || used < pLimit) {
                hasDoctorThatCanProtect = true;
                break;
              }
            }
          }
        }
      }

      // At classic parity, BOTH remaining abilities are required. Reevaluate
      // after the next death/night; firing consumes the sniper's chance.
      return hasUnusedSniper && hasDoctorThatCanProtect
          ? VictoryStatus.continueGame
          : VictoryStatus.mafiaWin;
    }

    return VictoryStatus.continueGame;
  }
}
