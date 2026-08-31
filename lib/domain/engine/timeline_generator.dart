import 'package:mafia_nightfall/domain/events/game_event.dart';

class TimelineGenerator {
  static String generateNarrative(List<GameEvent> events, String winnerTeam) {
    if (events.isEmpty) return 'لا توجد أحداث.';
    
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('📜 جريدة المدينة - التقرير الختامي');
    buffer.writeln('الفريق الفائز: $winnerTeam');
    buffer.writeln('===========================');
    
    int currentRound = 1;

    for (final event in events) {
      if (event.round > currentRound) {
        currentRound = event.round;
      }
      
      if (event.type == EventType.nightResolutionSummary) {
        if (event.round == 1) {
          buffer.writeln('\n🌙 الليلة الأولى:');
          buffer.writeln('نامت المدينة، وفتحت المافيا أعينها لتتعرف على بعضها البعض. ليلة هادئة قبل العاصفة.');
        } else {
          buffer.writeln('\n🌙 الليلة $currentRound:');
          final deadIds = (event.metadata['assassinatedIds'] as List?)?.cast<String>() ?? [];
          if (deadIds.isEmpty) {
            buffer.writeln('مرت الليلة بسلام! يبدو أن الطبيبة قامت بعملها أو أن المافيا أخطأت هدفها.');
          } else {
            buffer.writeln('سمعنا دوي رصاص في المدينة! استيقظنا لنجد جثة/جثث...');
          }
        }
      } else if (event.type == EventType.elimination) {
        buffer.writeln('\n☀️ نهار اليوم $currentRound:');
        buffer.writeln('احتد النقاش، وقرر أهل المدينة إعدام شخص بالديمقراطية...');
      } else if (event.type == EventType.citizenBoyRetaliation) {
        buffer.writeln('💥 مفاجأة! المواطن الشجاع (الولد) قرر ألا يموت وحيداً، وأخذ معه شخصاً آخر إلى القبر!');
      }
    }
    
    buffer.writeln('\n===========================');
    buffer.writeln('انتهت اللعبة بانتصار $winnerTeam!');
    
    return buffer.toString();
  }
}