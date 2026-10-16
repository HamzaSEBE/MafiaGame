import 'package:game_core/src/events/game_event.dart';
import 'package:game_core/src/entities/game_state.dart';
import 'night_casualties.dart';

class TimelineGenerator {
  static String generateNarrative(GameState state, String winnerTeam) {
    if (state.eventHistory.isEmpty) {
      return 'لا يوجد أحداث مسجلة. مرت الأيام بسلام.';
    }

    final StringBuffer buffer = StringBuffer();

    String getPlayerName(String? id) {
      if (id == null) return 'مجهول';
      try {
        return state.players.firstWhere((p) => p.id == id).name;
      } catch (_) {
        return 'مجهول';
      }
    }

    // Group events by round
    final eventsByRound = <int, List<GameEvent>>{};
    for (final event in state.eventHistory) {
      if (event.gameId != state.id) continue;
      eventsByRound.putIfAbsent(event.round, () => []).add(event);
    }

    final sortedRounds = eventsByRound.keys.toList()..sort();

    for (final r in sortedRounds) {
      final events = eventsByRound[r]!;

      // Night Summary
      final nightSummary = events
          .where((e) => e.type == EventType.nightResolutionSummary)
          .lastOrNull;
      if (nightSummary != null) {
        buffer.writeln('\n[ أحداث الليلة $r ]');

        final casualties = NightCasualties(nightSummary, events);
        final silencedIds =
            (nightSummary.metadata['silencedIds'] as List?)?.cast<String>() ??
            [];
        final successfulProtections =
            (nightSummary.metadata['successfulProtections'] as List?)
                ?.cast<String>() ??
            [];

        if (casualties.isEmpty) {
          buffer.writeln(
            'خيم الهدوء على المدينة هذه الليلة. لم يُسفك أي دم بفضل العناية الإلهية أو حكمة الطبيب.',
          );
        } else {
          if (casualties.mafia.isNotEmpty) {
            final names = casualties.mafia.map(getPlayerName).join(' و ');
            buffer.writeln(
              'اغتيال المافيا: في عتمة الليل، سقط ($names) ضحية للمافيا.',
            );
          }
          if (casualties.sniper.isNotEmpty) {
            final names = casualties.sniper.map(getPlayerName).join(' و ');
            buffer.writeln('ضحية القنص: أصابت رصاصة القنّاص ($names).');
          }
          if (casualties.unknown.isNotEmpty) {
            final names = casualties.unknown.map(getPlayerName).join(' و ');
            buffer.writeln(
              'ضحايا الليل: عُثر على ($names)، ولم يُسجّل سبب الوفاة.',
            );
          }
        }

        if (successfulProtections.isNotEmpty) {
          final protectedNames = successfulProtections
              .map((id) => getPlayerName(id))
              .join(' و ');
          buffer.writeln(
            'وقد تدخلت العناية لإنقاذ ($protectedNames) من موت محقق بفضل الحماية!',
          );
        }

        if (silencedIds.isNotEmpty) {
          final sNames = silencedIds.map((id) => getPlayerName(id)).join(' و ');
          buffer.writeln(
            'كما قامت المافيا بتكميم أفواه ($sNames)، ولن يتمكنوا من الدفاع عن أنفسهم نهاراً.',
          );
        }
      }

      // Voting Activity
      final votes = events.where((e) => e.type == EventType.vote).toList();
      if (votes.isNotEmpty) {
        buffer.writeln('\n[ قاعة المحكمة - النهار $r ]');
        buffer.writeln('احتد النقاش في قاعة المحكمة وتوزعت الأصوات كالتالي:');

        // Count who voted for who
        final voteMap = <String, List<String>>{}; // candidateId -> [voterNames]
        for (final v in votes) {
          voteMap
              .putIfAbsent(v.targetId ?? 'تخطي', () => [])
              .add(getPlayerName(v.actorId));
        }

        voteMap.forEach((candidateId, voters) {
          buffer.writeln(
            '- ($voters) قاموا بالتصويت ضد (${candidateId == 'تخطي' ? 'تخطي التصويت' : getPlayerName(candidateId)})',
          );
        });
      }

      // Eliminations
      final elimination = events
          .where((e) => e.type == EventType.elimination)
          .lastOrNull;
      if (elimination != null) {
        buffer.writeln(
          'وبعد تصويت حاسم، قررت الأغلبية إعدام (${getPlayerName(elimination.targetId)}).',
        );
      }

      // Retaliations
      final retaliation = events
          .where((e) => e.type == EventType.citizenBoyRetaliation)
          .lastOrNull;
      if (retaliation != null) {
        buffer.writeln(
          'مفاجأة صادمة! المواطن الشجاع (${getPlayerName(retaliation.actorId)}) رفض الموت وحيداً، وقام بسحب (${getPlayerName(retaliation.targetId)}) معه إلى القبر في لحظاته الأخيرة!',
        );
      }

      // Citizen Sheikh Reveal
      final reveal = events
          .where((e) => e.type == EventType.citizenSheikhReveal)
          .lastOrNull;
      if (reveal != null) {
        buffer.writeln(
          'قام شيخ المواطنين (${getPlayerName(reveal.actorId)}) بالكشف عن هويته علناً! وأصبح صوته يعادل 3 أصوات.',
        );
      }
    }

    buffer.writeln('\nالنتيجة النهائية: انتصار ساحق لـ $winnerTeam!');
    return buffer.toString();
  }
}
