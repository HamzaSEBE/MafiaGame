import re

with open('lib/domain/engine/voting_engine.dart', 'r') as f:
    content = f.read()

old_logic = "if (isMafia && state.rules.victoryRules.correctMafiaExecutions) {"
new_logic = "if (isMafia && state.rules.victoryRules.mode == VictoryMode.exactMafiaExecutions) {"

content = content.replace(old_logic, new_logic)

with open('lib/domain/engine/voting_engine.dart', 'w') as f:
    f.write(content)
