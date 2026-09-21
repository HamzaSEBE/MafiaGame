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

    for (var player in alivePlayers) {
      if (player.role.team == Team.mafia) {
        mafiaCount++;
      } else {
        citizensCount++;
      }
    }

    if (mafiaCount == 0) {
      return VictoryStatus.citizensWin;
    } 
    
    bool hasAliveCitizenKiller = alivePlayers.any((p) => p.role == Role.citizensBoy);

    if (mafiaCount > citizensCount) {
      return VictoryStatus.mafiaWin;
    } else if (mafiaCount == citizensCount && !hasAliveCitizenKiller) {
      return VictoryStatus.mafiaWin;
    }

    return VictoryStatus.continueGame;
  }
}
