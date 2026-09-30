import re

with open('lib/presentation/night/night_screen.dart', 'r') as f:
    content = f.read()

old_protection = """    // 4. Protection Step (Citizen Girl)
    final citizenGirl =
        alivePlayers.where((p) => p.role == Role.citizensGirl).firstOrNull;
    if (citizenGirl != null) {
      _activeSteps.add(_DynamicNightStep(
        actor: citizenGirl,
        arabicTitle: 'الحماية',
        arabicSubtitle: 'بواسطة بنت المواطنين',
        arabicAction:
            'بصوت عالي: "بنت المواطنين تفتح.. بنت المواطنين تحمي.. بنت المواطنين تغمض"',
        color: Colors.greenAccent,
        eventType: EventType.protection,
      ));
    }"""

new_protection = """    // 4. Protection Step (Citizen Girl)
    final citizenGirl =
        alivePlayers.where((p) => p.role == Role.citizensGirl).firstOrNull;
    if (citizenGirl != null) {
      _activeSteps.add(_DynamicNightStep(
        actor: citizenGirl,
        arabicTitle: 'الحماية',
        arabicSubtitle: 'بواسطة بنت المواطنين',
        arabicAction:
            'بصوت عالي: "بنت المواطنين تفتح.. بنت المواطنين تحمي.. بنت المواطنين تغمض"',
        color: Colors.greenAccent,
        eventType: EventType.protection,
      ));
    }

    // 5. Sniper Step
    if (state.rules.abilityRules.sniper) {
      final sniper = alivePlayers.where((p) => p.hasSniper).firstOrNull;
      if (sniper != null) {
        final hasShot = state.eventHistory.any((e) => e.type == EventType.sniperKill);
        if (!hasShot) {
          _activeSteps.add(_DynamicNightStep(
            actor: sniper,
            arabicTitle: 'القناص',
            arabicSubtitle: 'بواسطة المواطن القناص',
            arabicAction:
                'بصوت عالي: "القناص يفتح.. هل تريد القنص الليلة؟ اختر هدفك أو تخطى.. القناص يغمض"',
            color: Colors.amberAccent,
            eventType: EventType.sniperKill,
          ));
        }
      }
    }"""

content = content.replace(old_protection, new_protection)

old_can_select = """    if (step.eventType == EventType.investigation) {
      if (target.id == step.actor.id) return false;
    }"""

new_can_select = """    if (step.eventType == EventType.investigation) {
      if (target.id == step.actor.id) return false;
    }
    
    if (step.eventType == EventType.sniperKill) {
      if (target.id == step.actor.id) return false;
    }"""

content = content.replace(old_can_select, new_can_select)

with open('lib/presentation/night/night_screen.dart', 'w') as f:
    f.write(content)
