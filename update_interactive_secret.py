import re

with open('lib/domain/entities/interactive/models.dart', 'r') as f:
    content = f.read()

old_vars = """  final String id;
  final Role? role;
  final List<PlayerActionPrompt> requiredActions;
  final String? privateResult;
  final bool hasSubmittedAction;"""

new_vars = """  final String id;
  final Role? role;
  final List<PlayerActionPrompt> requiredActions;
  final String? privateResult;
  final bool hasSubmittedAction;
  final bool isSniper;"""

content = content.replace(old_vars, new_vars)

old_init = """  InteractiveSecret({
    required this.id,
    this.role,
    this.requiredActions = const [],
    this.privateResult,
    this.hasSubmittedAction = false,
  });"""

new_init = """  InteractiveSecret({
    required this.id,
    this.role,
    this.requiredActions = const [],
    this.privateResult,
    this.hasSubmittedAction = false,
    this.isSniper = false,
  });"""

content = content.replace(old_init, new_init)

old_tojson = """  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role?.name,
        'requiredActions':
            requiredActions.map((action) => action.toJson()).toList(),
        'requiredActionType': requiredActionType,
        'availableTargets': availableTargets,
        'privateResult': privateResult,
        'hasSubmittedAction': hasSubmittedAction,
      };"""

new_tojson = """  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role?.name,
        'requiredActions':
            requiredActions.map((action) => action.toJson()).toList(),
        'requiredActionType': requiredActionType,
        'availableTargets': availableTargets,
        'privateResult': privateResult,
        'hasSubmittedAction': hasSubmittedAction,
        'isSniper': isSniper,
      };"""

content = content.replace(old_tojson, new_tojson)

old_fromjson = """    return InteractiveSecret(
      id: json['id'] as String,
      role: json['role'] != null
          ? Role.values.byName(json['role'] as String)
          : null,
      requiredActions: prompts,
      privateResult: json['privateResult'] as String?,
      hasSubmittedAction: json['hasSubmittedAction'] as bool? ?? false,
    );"""

new_fromjson = """    return InteractiveSecret(
      id: json['id'] as String,
      role: json['role'] != null
          ? Role.values.byName(json['role'] as String)
          : null,
      requiredActions: prompts,
      privateResult: json['privateResult'] as String?,
      hasSubmittedAction: json['hasSubmittedAction'] as bool? ?? false,
      isSniper: json['isSniper'] as bool? ?? false,
    );"""

content = content.replace(old_fromjson, new_fromjson)

with open('lib/domain/entities/interactive/models.dart', 'w') as f:
    f.write(content)
