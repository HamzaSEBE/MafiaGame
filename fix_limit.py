import re

with open('lib/presentation/night/night_screen.dart', 'r') as f:
    content = f.read()

old_logic = """    if (step.eventType == EventType.silence) {
      final pastSilences = state.eventHistory.where((e) =>
          e.type == EventType.silence &&
          e.actorId == step.actor.id &&
          e.targetId == target.id);
      if (pastSilences.isNotEmpty) return false;
    }

    if (step.eventType == EventType.protection) {
      final pastProtections = state.eventHistory.where((e) =>
          e.type == EventType.protection &&
          e.actorId == step.actor.id &&
          e.targetId == target.id);
      if (pastProtections.isNotEmpty) return false;
    }"""

new_logic = """    final limit = state.rules.abilityRules.repeatedTargetLimit;

    if (step.eventType == EventType.silence) {
      final pastSilences = state.eventHistory.where((e) =>
          e.type == EventType.silence &&
          e.actorId == step.actor.id &&
          e.targetId == target.id);
      if (limit != -1 && pastSilences.length >= limit) return false;
    }

    if (step.eventType == EventType.protection) {
      final pastProtections = state.eventHistory.where((e) =>
          e.type == EventType.protection &&
          e.actorId == step.actor.id &&
          e.targetId == target.id);
      if (limit != -1 && pastProtections.length >= limit) return false;
    }"""

content = content.replace(old_logic, new_logic)

with open('lib/presentation/night/night_screen.dart', 'w') as f:
    f.write(content)
