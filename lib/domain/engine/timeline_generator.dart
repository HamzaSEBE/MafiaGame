import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';

class TimelineGenerator {
  static String generateNarrative(GameState state, String winnerTeam) {
    if (state.eventHistory.isEmpty) return 'لا توجد أحداث.';
    
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('📜 جريدة المدينة - التقرير الختامي');
    buffer.writeln('الفريق الفائز: $winnerTeam');
    buffer.writeln('===========================');
    
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
        if (event.round == 1) {
          buffer.writeln('\n🌙 الليلة الأولى:');
        } else {
          buffer.writeln('\n🌙 الليلة $currentRound:');
        }
        final deadIds = (event.metadata['assassinatedIds'] as List?)?.cast<String>() ?? [];
        if (deadIds.isEmpty) {
          buffer.writeln('مرت الليلة بسلام! يبدو أن الحماية نجحت أو المافيا أخطأت.');
        } else {
          final names = deadIds.map((id) => getPlayerName(id)).join(' و ');
          buffer.writeln('استيقظت المدينة على فاجعة.. تم العثور على جثة: $names!');
        }
      } else if (event.type == EventType.assassination) {
         buffer.writeln('🔫 قرر ${getPlayerName(event.actorId)} (المافيا) اغتيال ${getPlayerName(event.targetId)}.');
      } else if (event.type == EventType.protection) {
         buffer.writeln('🛡️ حاولت الطبيبة ${getPlayerName(event.actorId)} حماية ${getPlayerName(event.targetId)}.');
      } else if (event.type == EventType.silence) {
         buffer.writeln('🤫 قامت بنت المافيا ${getPlayerName(event.actorId)} بإسكات ${getPlayerName(event.targetId)}.');
      } else if (event.type == EventType.investigation) {
         buffer.writeln('🔍 قام المحقق ${getPlayerName(event.actorId)} بالتحري عن ${getPlayerName(event.targetId)}.');
      } else if (event.type == EventType.elimination) {
        buffer.writeln('\n☀️ نهار اليوم $currentRound:');
        buffer.writeln('⚖️ بعد نقاشات وتصويتات، قرر أهل المدينة إعدام ${getPlayerName(event.targetId)}.');
      } else if (event.type == EventType.vote) {
        buffer.writeln('🗣️ صوّت ${getPlayerName(event.actorId)} ضد ${getPlayerName(event.targetId)}.');
      } else if (event.type == EventType.citizenBoyRetaliation) {
        buffer.writeln('💥 مفاجأة! المواطن الشجاع (الولد) ${getPlayerName(event.actorId)} أخذ ثأره وقتل ${getPlayerName(event.targetId)} قبل أن يموت!');
      }
    }
    
    buffer.writeln('\n===========================');
    buffer.writeln('انتهت اللعبة بانتصار $winnerTeam!');
    
    return buffer.toString();
  }
}