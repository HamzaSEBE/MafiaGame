import 'dart:io';

void main() {
  final file = File('lib/domain/engine/timeline_generator.dart');
  var content = """
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';

class TimelineGenerator {
  static String generateNarrative(GameState state, String winnerTeam) {
    if (state.eventHistory.isEmpty) return 'لا يوجد أحداث تذكر. مرّت الأيام بسلام.';
    
    final StringBuffer buffer = StringBuffer();
    
    int currentRound = 1;

    String getPlayerName(String? id) {
      if (id == null) return 'مجهول';
      try {
        return state.players.firstWhere((p) => p.id == id).name;
      } catch (_) {
        return 'مجهول';
      }
    }

    for (final event in state.eventHistory) {
      if (event.round > currentRound) {
        currentRound = event.round;
      }
      
      if (event.type == EventType.nightResolutionSummary) {
        buffer.writeln('\n[ أحداث الليلة \$currentRound ]');
        
        final deadIds = (event.metadata['assassinatedIds'] as List?)?.cast<String>() ?? [];
        if (deadIds.isEmpty) {
          buffer.writeln('خيم الهدوء على المدينة هذه الليلة. لم تُسفك الدماء بفضل حنكة الأطباء، أو ربما أخطأت المافيا هدفها.');
        } else {
          final names = deadIds.map((id) => getPlayerName(id)).join(' و ');
          buffer.writeln('في جنح الظلام، تحركت الأيادي الخفية ونفذت حكم الإعدام بحق (\$names). استيقظت المدينة على فاجعة هزت الأرجاء!');
        }
      } else if (event.type == EventType.elimination) {
        buffer.writeln('\n[ نهار اليوم \$currentRound ]');
        buffer.writeln('بعد نقاشات حادة واتهامات متبادلة، أجمعت الأغلبية الغاضبة على شنق (\$getPlayerName(event.targetId)). تم تنفيذ الحكم بلا رحمة.');
      } else if (event.type == EventType.citizenBoyRetaliation) {
        buffer.writeln('مفاجأة دموية! في لحظاته الأخيرة، سحب ولد المواطنين (\$getPlayerName(event.actorId)) مسدسه وأردى (\$getPlayerName(event.targetId)) قتيلاً قبل أن يلفظ أنفاسه الأخيرة.');
      }
    }
    
    buffer.writeln('\n-------------------');
    buffer.writeln('النتيجة النهائية: انتصر \$winnerTeam وسيطروا على المدينة بالكامل.');
    
    return buffer.toString();
  }
}
""";
  file.writeAsStringSync(content);
}