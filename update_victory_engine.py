import re

with open('lib/domain/engine/victory_engine.dart', 'r') as f:
    content = f.read()

old_logic = """      int nonMafiaVotes = 0;
      int mafiaVotes = 0;
      bool hasUnusedSniper = false;
      bool hasDoctor = false;
      
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
            hasDoctor = true;
          }
        }
      }
      
      // If Citizens have equal or less voting power than Mafia, Mafia wins...
      if (nonMafiaVotes <= mafiaVotes) {
        // ...EXCEPT in one single case: Both an unused Sniper and the Doctor are alive.
        if (hasUnusedSniper && hasDoctor) {
          // They get one last night to try and turn the tide!
        } else {
          return VictoryStatus.mafiaWin;
        }
      }"""

new_logic = """      int nonMafiaVotes = 0;
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
      }"""

content = content.replace(old_logic, new_logic)

with open('lib/domain/engine/victory_engine.dart', 'w') as f:
    f.write(content)
