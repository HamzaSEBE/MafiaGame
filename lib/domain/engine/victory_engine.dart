import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';

enum VictoryStatus {
  mafiaWin,
  citizensWin,
  jokerWin,
  continueGame,
}

class VictoryEngine {
  static VictoryStatus evaluate(GameState state) {
    // 0. Check if Joker was just voted out
    if (state.eventHistory.isNotEmpty) {
      final lastEvent = state.eventHistory.last;
      if (lastEvent.type == EventType.elimination && lastEvent.targetId != null) {
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

    // RULE: Correct Mafia Executions (Exact Mafia Count Victory)
    if (vRules.mode == VictoryMode.exactMafiaExecutions && state.correctMafiaExecutionsCount >= vRules.requiredCorrectExecutions) {
      return VictoryStatus.citizensWin;
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
    if (vRules.mode == VictoryMode.classic) {
      // If all mafia are dead, citizens win immediately
      if (mafiaCount == 0) {
        return VictoryStatus.citizensWin;
      } 
      
      int nonMafiaVotes = 0;
      int mafiaVotes = 0;
      bool hasUnusedSniper = false;
      bool hasDoctorThatCanProtect = false;
      
      final pLimit = state.rules.abilityRules.protectionTargetLimit;

      for (var p in alivePlayers) {
        int weight = p.isCitizenSheikhRevealed ? 3 : 1;
        if (p.role.team == Team.mafia) {
          mafiaVotes += weight;
        } else {
          nonMafiaVotes += weight;
          
          if (p.hasSniper) {
            final hasShot = state.eventHistory.any((e) => e.type == EventType.sniperKill);
            if (!hasShot) hasUnusedSniper = true;
          }
          if (p.role == Role.citizensGirl) {
            // Check if she can protect ANY alive citizen (or herself)
            for (var target in alivePlayers) {
              if (target.role.team == Team.citizens || target.id == p.id) {
                final pastProtections = state.eventHistory.where((e) =>
                    e.type == EventType.protection &&
                    e.actorId == p.id &&
                    e.targetId == target.id);
                if (pLimit == -1 || pastProtections.length < pLimit) {
                  hasDoctorThatCanProtect = true;
                  break;
                }
              }
            }
          }
        }
      }
      
      // If Citizens have equal or less voting power than Mafia, Mafia wins...
      if (nonMafiaVotes <= mafiaVotes) {
        // ...EXCEPT in one single case: Both an unused Sniper and a Doctor who can still protect someone are alive.
        if (hasUnusedSniper && hasDoctorThatCanProtect) {
          // They get one last night to try and turn the tide!
        } else {
          return VictoryStatus.mafiaWin;
        }
      }
    }

    return VictoryStatus.continueGame;
  }
}
