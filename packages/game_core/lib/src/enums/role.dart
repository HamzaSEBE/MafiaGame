import 'package:game_core/src/enums/team.dart';

export 'package:game_core/src/enums/team.dart';

enum Role {
  mafiaSheikh,
  mafiaGirl,
  normalMafia,
  goodCitizen,
  citizensSheikh,
  citizensGirl,
  citizensBoy,
  joker,
}

extension RoleExtension on Role {
  Team get team {
    switch (this) {
      case Role.mafiaSheikh:
      case Role.mafiaGirl:
      case Role.normalMafia:
        return Team.mafia;
      case Role.goodCitizen:
      case Role.citizensSheikh:
      case Role.citizensGirl:
      case Role.citizensBoy:
        return Team.citizens;
      case Role.joker:
        return Team.independent;
    }
  }
}
