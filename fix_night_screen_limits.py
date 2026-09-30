import re

with open('lib/presentation/night/night_screen.dart', 'r') as f:
    content = f.read()

old_logic = """    final limit = state.rules.abilityRules.repeatedTargetLimit;

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

new_logic = """    final pLimit = state.rules.abilityRules.protectionTargetLimit;
    final sLimit = state.rules.abilityRules.silenceTargetLimit;

    if (step.eventType == EventType.silence) {
      final pastSilences = state.eventHistory.where((e) =>
          e.type == EventType.silence &&
          e.actorId == step.actor.id &&
          e.targetId == target.id);
      if (sLimit != -1 && pastSilences.length >= sLimit) return false;
    }

    if (step.eventType == EventType.protection) {
      final pastProtections = state.eventHistory.where((e) =>
          e.type == EventType.protection &&
          e.actorId == step.actor.id &&
          e.targetId == target.id);
      if (pLimit != -1 && pastProtections.length >= pLimit) return false;
    }"""

content = content.replace(old_logic, new_logic)

with open('lib/presentation/night/night_screen.dart', 'w') as f:
    f.write(content)
