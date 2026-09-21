import 'package:mafia_nightfall/domain/enums/team.dart';

export 'package:mafia_nightfall/domain/enums/team.dart';

enum Role {
  mafiaSheikh,
  mafiaGirl,
  normalMafia,
  goodCitizen,
  citizensSheikh,
  citizensGirl,
  citizensBoy,
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
    }
  }
}
