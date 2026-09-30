import re

with open('lib/domain/engine/victory_engine.dart', 'r') as f:
    content = f.read()

old_classic = """    // RULE: Classic Victory
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
    }"""

new_classic = """    // RULE: Classic Victory
    if (vRules.mode == VictoryMode.classic) {
      // If all mafia are dead, citizens win immediately
      if (mafiaCount == 0) {
        return VictoryStatus.citizensWin;
      } 
      
      int nonMafiaVotes = 0;
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
      }
    }"""

content = content.replace(old_classic, new_classic)

with open('lib/domain/engine/victory_engine.dart', 'w') as f:
    f.write(content)
