import re

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'r') as f:
    content = f.read()

old_func = """    final citizenGirl =
        alive.where((p) => p.role == Role.citizensGirl).firstOrNull;
    if (citizenGirl != null) {
      final previouslyProtected = state.eventHistory
          .where((event) =>
              event.type == EventType.protection &&
              event.actorId == citizenGirl.id)
          .map((event) => event.targetId)
          .whereType<String>()
          .toSet();
      final targets =
          aliveIds.where((id) => !previouslyProtected.contains(id)).toList();
      if (targets.isNotEmpty) {
        _addPrompt(prompts, citizenGirl.id,
            PlayerActionPrompt(type: 'protection', availableTargets: targets));
      }
    }
    return prompts;
  }"""

new_func = """    final citizenGirl =
        alive.where((p) => p.role == Role.citizensGirl).firstOrNull;
    if (citizenGirl != null) {
      final previouslyProtected = state.eventHistory
          .where((event) =>
              event.type == EventType.protection &&
              event.actorId == citizenGirl.id)
          .map((event) => event.targetId)
          .whereType<String>()
          .toSet();
      final targets =
          aliveIds.where((id) => !previouslyProtected.contains(id)).toList();
      if (targets.isNotEmpty) {
        _addPrompt(prompts, citizenGirl.id,
            PlayerActionPrompt(type: 'protection', availableTargets: targets));
      }
    }

    final snipers = alive.where((p) => p.hasSniper).toList();
    for (var sniper in snipers) {
      final hasShot = state.eventHistory.any((e) => e.type == EventType.sniperKill && e.actorId == sniper.id);
      if (!hasShot) {
        final targets = aliveIds.toList(); // Includes himself so he can skip by selecting himself
        _addPrompt(prompts, sniper.id, PlayerActionPrompt(type: 'sniperKill', availableTargets: targets));
      }
    }

    for (var id in aliveIds) {
      if (!prompts.containsKey(id) || prompts[id]!.isEmpty) {
        _addPrompt(prompts, id, PlayerActionPrompt(type: 'sleep', availableTargets: [id]));
      }
    }

    return prompts;
  }"""

content = content.replace(old_func, new_func)

with open('lib/presentation/interactive/judge_dashboard_screen.dart', 'w') as f:
    f.write(content)
