import re

with open('lib/domain/engine/timeline_generator.dart', 'r') as f:
    content = f.read()

old_timeline = """        if (deadIds.isEmpty) {
          buffer.writeln('خيم الهدوء على المدينة هذه الليلة. لم يُسفك أي دم بفضل العناية الإلهية أو حكمة الطبيب.');
        } else {
          final names = deadIds.map((id) => getPlayerName(id)).join(' و ');
          buffer.writeln('في عتمة الليل، نفذت المافيا حكمها القاسي، واستيقظت المدينة على جثة ($names).');
        }"""

new_timeline = """        final sniperKills = events.where((e) => e.type == EventType.sniperKill).toList();
        
        if (deadIds.isEmpty) {
          buffer.writeln('خيم الهدوء على المدينة هذه الليلة. لم يُسفك أي دم بفضل العناية الإلهية أو حكمة الطبيب.');
        } else {
          final names = deadIds.map((id) => getPlayerName(id)).join(' و ');
          if (sniperKills.isNotEmpty) {
            buffer.writeln('في عتمة الليل، نفذت المافيا حكمها، وقام قناص مجهول بإطلاق رصاصة قاتلة، واستيقظت المدينة على جثث ($names).');
          } else {
            buffer.writeln('في عتمة الليل، نفذت المافيا حكمها القاسي، واستيقظت المدينة على جثة ($names).');
          }
        }"""

content = content.replace(old_timeline, new_timeline)

old_retaliation = """      // Retaliations
      final retaliation = events.where((e) => e.type == EventType.citizenBoyRetaliation).lastOrNull;
      if (retaliation != null) {
        buffer.writeln('مفاجأة صادمة! المواطن الشجاع (${getPlayerName(retaliation.actorId)}) رفض الموت وحيداً، وقام بسحب (${getPlayerName(retaliation.targetId)}) معه إلى القبر في لحظاته الأخيرة!');
      }"""

new_retaliation = """      // Retaliations
      final retaliation = events.where((e) => e.type == EventType.citizenBoyRetaliation).lastOrNull;
      if (retaliation != null) {
        buffer.writeln('مفاجأة صادمة! المواطن الشجاع (${getPlayerName(retaliation.actorId)}) رفض الموت وحيداً، وقام بسحب (${getPlayerName(retaliation.targetId)}) معه إلى القبر في لحظاته الأخيرة!');
      }

      // Citizen Sheikh Reveal
      final reveal = events.where((e) => e.type == EventType.citizenSheikhReveal).lastOrNull;
      if (reveal != null) {
        buffer.writeln('قام شيخ المواطنين (${getPlayerName(reveal.actorId)}) بالكشف عن هويته علناً! وأصبح صوته يعادل 3 أصوات.');
      }"""

content = content.replace(old_retaliation, new_retaliation)

with open('lib/domain/engine/timeline_generator.dart', 'w') as f:
    f.write(content)
