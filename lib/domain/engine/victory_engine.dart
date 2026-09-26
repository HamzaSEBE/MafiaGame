import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';

enum VictoryStatus {
  mafiaWin,
  citizensWin,
  continueGame,
}

class VictoryEngine {
  static VictoryStatus evaluate(GameState state) {
    final alivePlayers = state.alivePlayers;
    
    int mafiaCount = 0;
    int citizensCount = 0;
    bool hasAliveCitizenBoy = false;
    bool hasAliveDoctor = false;

    for (var player in alivePlayers) {
      if (player.role.team == Team.mafia) {
        mafiaCount++;
      } else {
        citizensCount++;
        if (player.role == Role.citizensBoy) hasAliveCitizenBoy = true;
        if (player.role == Role.citizensGirl) hasAliveDoctor = true;
      }
    }

    // 1. If all mafia are dead, citizens win immediately.
    // (Even if 0 citizens are left, it means the boy took the last mafia down with him -> Citizens win in this game's logic)
    if (mafiaCount == 0) {
      return VictoryStatus.citizensWin;
    } 
    
    // 2. If Mafia strictly outnumbers citizens, they have an absolute majority.
    // Even if Citizen Boy is voted out or killed, he can only take 1 mafia, leaving mafia still alive.
    if (mafiaCount > citizensCount) {
      return VictoryStatus.mafiaWin;
    } 
    
    // 3. If Mafia equals Citizens (e.g. 1v1, 2v2)
    if (mafiaCount == citizensCount) {
      // If the Doctor is alive, they can protect themselves/others, forcing a stalemate or mistake.
      if (hasAliveDoctor) {
        return VictoryStatus.continueGame;
      }
      
      // If the Citizen Boy is alive, his death will take down a Mafia.
      // If it's 1v1, he takes down the last Mafia -> Citizens Win!
      // If it's 2v2, he takes down 1 Mafia -> 1v1 remaining.
      if (hasAliveCitizenBoy) {
        return VictoryStatus.continueGame;
      }
      
      // If neither Doctor nor Citizen Boy is alive, Citizens have no mathematical chance.
      // They can't win a vote (tied), and Mafia will just kill one of them at night.
      return VictoryStatus.mafiaWin;
    }

    // Otherwise, continue
    return VictoryStatus.continueGame;
  }
}
