import re

with open('lib/data/services/interactive/interactive_service.dart', 'r') as f:
    content = f.read()

old_json = """      final secretData = <String, dynamic>{
        'role': player.role.name,
        'requiredActions': prompts.map((action) => action.toJson()).toList(),
        'requiredActionType': prompts.isEmpty ? null : prompts.first.type,
        'availableTargets':
            prompts.isEmpty ? null : prompts.first.availableTargets,
        'hasSubmittedAction': false,
      };"""

new_json = """      final secretData = <String, dynamic>{
        'role': player.role.name,
        'requiredActions': prompts.map((action) => action.toJson()).toList(),
        'requiredActionType': prompts.isEmpty ? null : prompts.first.type,
        'availableTargets':
            prompts.isEmpty ? null : prompts.first.availableTargets,
        'hasSubmittedAction': false,
        'isSniper': player.hasSniper,
      };"""

content = content.replace(old_json, new_json)

with open('lib/data/services/interactive/interactive_service.dart', 'w') as f:
    f.write(content)
