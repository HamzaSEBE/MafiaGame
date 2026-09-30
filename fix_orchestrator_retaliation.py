import re

with open('lib/application/game_orchestrator.dart', 'r') as f:
    content = f.read()

old_code = """      if (victoryStatus == VictoryStatus.mafiaWin)
        winner = Team.mafia;
      else if (victoryStatus == VictoryStatus.jokerWin)
        winner = Team.independent;
      else
        winner = Team.citizens;
      nextState = nextState.copyWith(phase: Phase.winCheck, winner: winner);"""
    
new_code = """      if (victoryStatus == VictoryStatus.mafiaWin)
        winner = Team.mafia;
      else if (victoryStatus == VictoryStatus.jokerWin)
        winner = Team.independent;
      else
        winner = Team.citizens;
        
      String? reason;
      int aliveCitizensCount = nextState.alivePlayers.where((p) => p.role.team == Team.citizens).length;
      if (winner == Team.mafia && nextState.rules.victoryRules.initialMafiaParity && aliveCitizensCount <= nextState.initialMafiaCount) reason = 'التعادل مع العدد الأصلي للمافيا';
      else if (winner == Team.citizens && nextState.rules.victoryRules.correctMafiaExecutions && nextState.correctMafiaExecutionsCount >= nextState.rules.victoryRules.requiredCorrectExecutions) reason = 'إعدامات صحيحة للمافيا';
      else if (winner == Team.independent) reason = 'إقصاء الجوكر بالتصويت';
      else if (winner == Team.mafia) reason = 'سيطرة المافيا';
      else reason = 'القضاء على المافيا';
      
      nextState = nextState.copyWith(phase: Phase.winCheck, winner: winner, victoryReason: reason);"""

content = content.replace(old_code, new_code)

with open('lib/application/game_orchestrator.dart', 'w') as f:
    f.write(content)
