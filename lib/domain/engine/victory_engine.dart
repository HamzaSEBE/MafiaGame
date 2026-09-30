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
      
      // Check if Citizens still have a legal path to eliminate Mafia
      bool citizensCanWin = false;
      int nonMafiaVotes = 0;
      int mafiaVotes = 0;
      
      for (var p in alivePlayers) {
        int weight = p.isCitizenSheikhRevealed ? 3 : 1;
        if (p.role.team == Team.mafia) {
          mafiaVotes += weight;
        } else {
          nonMafiaVotes += weight;
          
          if (p.role == Role.citizensBoy) {
            citizensCanWin = true;
          }
          if (p.hasSniper) {
            final hasShot = state.eventHistory.any((e) => e.type == EventType.sniperKill);
            if (!hasShot) citizensCanWin = true;
          }
        }
      }
      
      // If Citizens have more voting power than Mafia, they can still legally outvote them.
      if (nonMafiaVotes > mafiaVotes) {
        citizensCanWin = true;
      }
      
      // If Citizens have absolutely no remaining legal way to eliminate Mafia, and Mafia is still alive.
      // The Mafia is guaranteed to win eventually.
      if (!citizensCanWin) {
        return VictoryStatus.mafiaWin;
      }
    }

    return VictoryStatus.continueGame;
  }
}
