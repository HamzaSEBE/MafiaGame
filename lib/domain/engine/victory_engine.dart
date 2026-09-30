import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';

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
    int citizensCount = 0;
    int jokerCount = 0;
    bool hasAliveCitizenBoy = false;
    bool hasAliveDoctor = false;

    for (var player in alivePlayers) {
      if (player.role.team == Team.mafia) {
        mafiaCount++;
      } else if (player.role.team == Team.citizens) {
        citizensCount++;
        if (player.role == Role.citizensBoy) hasAliveCitizenBoy = true;
        if (player.role == Role.citizensGirl) hasAliveDoctor = true;
      } else {
        jokerCount++;
      }
    }

    final vRules = state.rules.victoryRules;

    // RULE: Correct Mafia Executions
    if (vRules.correctMafiaExecutions && state.correctMafiaExecutionsCount >= vRules.requiredCorrectExecutions) {
      return VictoryStatus.citizensWin;
    }

    // RULE: Initial Mafia Count Parity
    if (vRules.initialMafiaParity) {
      if (mafiaCount == 0) {
        return VictoryStatus.citizensWin;
      }
      if (citizensCount <= state.initialMafiaCount) {
        return VictoryStatus.mafiaWin;
      }
      return VictoryStatus.continueGame;
    }

    // RULE: Classic Victory (Default)
    if (vRules.classicVictory) {
      // 1. If all mafia are dead, citizens win immediately (Joker loses because he survived!).
      if (mafiaCount == 0) {
        return VictoryStatus.citizensWin;
      } 
      
      // 2. If Mafia strictly outnumbers everyone else, they have an absolute majority.
      if (mafiaCount > citizensCount + jokerCount) {
        return VictoryStatus.mafiaWin;
      } 
      
      // 3. If Mafia equals Citizens + Jokers (e.g. 1v1, 2v2)
      if (mafiaCount == (citizensCount + jokerCount)) {
        if (hasAliveDoctor || hasAliveCitizenBoy) {
          return VictoryStatus.continueGame;
        }
        return VictoryStatus.mafiaWin;
      }

      // 4. Special case: If 0 citizens left, but Joker is alive. Mafia wins because they won't vote Joker.
      if (citizensCount == 0 && mafiaCount > 0) {
        return VictoryStatus.mafiaWin;
      }
    }

    return VictoryStatus.continueGame;
  }
}
