import re

with open('lib/domain/engine/night_resolution_engine.dart', 'r') as f:
    content = f.read()

old_deaths = """    // 5. Calculate deaths
    final deadPlayerIds = <String>{};
    for (var targetId in finalAssassinationTargets) {
      if (!protectedTargetIds.contains(targetId)) {
        deadPlayerIds.add(targetId);
      }
    }"""

new_deaths = """    // Sniper Kills
    final sniperKills = nightEvents.where((e) => e.type == EventType.sniperKill).toList();
    for (var kill in sniperKills) {
      if (kill.targetId != null) {
        finalAssassinationTargets.add(kill.targetId!);
      }
    }

    // 5. Calculate deaths
    final deadPlayerIds = <String>{};
    for (var targetId in finalAssassinationTargets) {
      if (!protectedTargetIds.contains(targetId)) {
        deadPlayerIds.add(targetId);
      }
    }"""

content = content.replace(old_deaths, new_deaths)

with open('lib/domain/engine/night_resolution_engine.dart', 'w') as f:
    f.write(content)
