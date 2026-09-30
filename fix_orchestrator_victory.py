import re

with open('lib/application/game_orchestrator.dart', 'r') as f:
    content = f.read()

def replace_reason(text):
    old_code = """      String? reason;
      int aliveCitizensCount = nextState.alivePlayers.where((p) => p.role.team == Team.citizens).length;
      if (winner == Team.mafia && nextState.rules.victoryRules.initialMafiaParity && aliveCitizensCount <= nextState.initialMafiaCount) reason = 'التعادل مع العدد الأصلي للمافيا';
      else if (winner == Team.citizens && nextState.rules.victoryRules.correctMafiaExecutions && nextState.correctMafiaExecutionsCount >= nextState.rules.victoryRules.requiredCorrectExecutions) reason = 'إعدامات صحيحة للمافيا';
      else if (winner == Team.independent) reason = 'إقصاء الجوكر بالتصويت';
      else if (winner == Team.mafia) reason = 'سيطرة المافيا';
      else reason = 'القضاء على المافيا';"""

    new_code = """      String? reason;
      int aliveCitizensCount = nextState.alivePlayers.where((p) => p.role.team == Team.citizens).length;
      if (winner == Team.mafia && nextState.rules.victoryRules.mode == VictoryMode.equalCount && aliveCitizensCount <= nextState.initialMafiaCount) reason = 'التعادل مع العدد الأصلي للمافيا';
      else if (winner == Team.citizens && nextState.rules.victoryRules.mode == VictoryMode.exactMafiaExecutions && nextState.correctMafiaExecutionsCount >= nextState.rules.victoryRules.requiredCorrectExecutions) reason = 'إعدامات صحيحة للمافيا';
      else if (winner == Team.independent) reason = 'إقصاء الجوكر بالتصويت';
      else if (winner == Team.mafia) reason = 'استحالة فوز المواطنين';
      else reason = 'القضاء التام على المافيا';"""

    return text.replace(old_code, new_code)

content = replace_reason(content)

# Add import for GameRuleset
if "import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';" not in content:
    content = content.replace("import 'package:mafia_nightfall/domain/events/game_event.dart';", "import 'package:mafia_nightfall/domain/events/game_event.dart';\nimport 'package:mafia_nightfall/domain/rules/game_ruleset.dart';")


with open('lib/application/game_orchestrator.dart', 'w') as f:
    f.write(content)
