import 'package:flutter/material.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class NewspaperWidget extends StatelessWidget {
  final GameState gameState;

  const NewspaperWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECD8),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          )
        ],
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [Color(0xFFF4ECD8), Color(0xFFE8DDBF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'العدد: ${now.millisecondsSinceEpoch.toString().substring(5, 10)}',
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 2, color: Colors.black87),
            Container(height: 5, margin: const EdgeInsets.only(top: 2), color: Colors.black87),
            const SizedBox(height: 16),
            
            const Text(
              'جريدة المدينة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -1,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            const Text(
              'أخبار المافيا العاجلة - النسخة الحصرية',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(height: 2, color: Colors.black87),
            const SizedBox(height: 24),
            
            _buildArticleBody(),
            
            const SizedBox(height: 32),
            Container(height: 1, color: Colors.black38),
            const SizedBox(height: 12),
            const Text(
              'طُبعت في مطابع المدينة السرية - جميع الحقوق محفوظة ©',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleBody() {
    if (gameState.eventHistory.isEmpty) {
      return const Text(
        'لا يوجد أحداث مسجلة. مرت الأيام بسلام.',
        style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.black87),
        textAlign: TextAlign.center,
      );
    }

    List<Widget> sections = [];
    final eventsByRound = <int, List<GameEvent>>{};
    for (final event in gameState.eventHistory) {
      eventsByRound.putIfAbsent(event.round, () => []).add(event);
    }
    
    final sortedRounds = eventsByRound.keys.toList()..sort();
    
    for (final r in sortedRounds) {
      final events = eventsByRound[r]!;
      sections.add(_buildRoundSection(r, events));
    }
    
    sections.add(_buildConclusion());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }

  Widget _buildRoundSection(int round, List<GameEvent> events) {
    List<Widget> roundWidgets = [];

    // Night Summary
    final nightSummary = events.where((e) => e.type == EventType.nightResolutionSummary).lastOrNull;
    if (nightSummary != null) {
      roundWidgets.add(_buildSectionHeader('أحداث الليلة $round', Icons.nights_stay));
      
      final deadIds = (nightSummary.metadata['assassinatedIds'] as List?)?.cast<String>() ?? [];
      final silencedIds = (nightSummary.metadata['silencedIds'] as List?)?.cast<String>() ?? [];
      final successfulProtections = (nightSummary.metadata['successfulProtections'] as List?)?.cast<String>() ?? [];

      if (deadIds.isEmpty) {
        roundWidgets.add(_buildInfoRow('خيم الهدوء على المدينة. لم يُسفك أي دم.', '🕊️'));
      } else {
        roundWidgets.add(_buildEventRow('اغتيال المافيا:', '🔫', deadIds, const Color(0xFF8B0000)));
      }

      if (successfulProtections.isNotEmpty) {
        roundWidgets.add(_buildEventRow('تدخل الطبيب وأنقذ:', '🛡️', successfulProtections, const Color(0xFF006400)));
      }

      if (silencedIds.isNotEmpty) {
        roundWidgets.add(_buildEventRow('تم تكميم أفواه:', '🤐', silencedIds, Colors.black87));
      }
    }

    // Voting Activity
    final votes = events.where((e) => e.type == EventType.vote).toList();
    if (votes.isNotEmpty) {
      roundWidgets.add(_buildSectionHeader('قاعة المحكمة - النهار $round', Icons.gavel));
      
      final voteMap = <String, List<String>>{};
      for (final v in votes) {
        voteMap.putIfAbsent(v.targetId ?? 'تخطي', () => []).add(v.actorId ?? '');
      }
      
      List<Widget> voteRows = [];
      voteMap.forEach((candidateId, voters) {
        voteRows.add(_buildVoteCard(candidateId, voters));
      });
      
      roundWidgets.add(Column(children: voteRows));
    }

    // Eliminations
    final elimination = events.where((e) => e.type == EventType.elimination).lastOrNull;
    if (elimination != null) {
      roundWidgets.add(_buildEventCard(
        title: 'قرار المحكمة (إعدام)',
        emoji: '⚖️',
        targetId: elimination.targetId,
        color: const Color(0xFF8B0000),
      ));
    }

    // Retaliations
    final retaliation = events.where((e) => e.type == EventType.citizenBoyRetaliation).lastOrNull;
    if (retaliation != null) {
      roundWidgets.add(_buildRetaliationCard(
        actorId: retaliation.actorId,
        targetId: retaliation.targetId,
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: roundWidgets,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              decoration: TextDecoration.underline,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.black87, size: 28),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text, String emoji) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildEventRow(String title, String emoji, List<String> playerIds, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        border: Border(right: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(emoji, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: playerIds.map((id) => _buildPlayerAvatar(id)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteCard(String candidateId, List<String> voters) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          if (candidateId == 'تخطي')
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'تخطي التصويت',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            )
          else
            _buildPlayerAvatar(candidateId),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.how_to_vote, color: Colors.black54, size: 32),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              textDirection: TextDirection.rtl,
              children: voters.map((id) => _buildPlayerAvatar(id, small: true)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({required String title, required String emoji, String? targetId, required Color color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (targetId != null) _buildPlayerAvatar(targetId),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              Text(
                title,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetaliationCard({String? actorId, String? targetId}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withValues(alpha: 0.2), Colors.red.withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepOrange),
      ),
      child: Column(
        children: [
          const Text(
            '💥 انتقام المواطن الشجاع!',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (actorId != null) _buildPlayerAvatar(actorId),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.double_arrow, color: Colors.deepOrange, size: 32),
              ),
              if (targetId != null) _buildPlayerAvatar(targetId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar(String id, {bool small = false}) {
    final player = gameState.getPlayerById(id);
    if (player == null) return const SizedBox.shrink();

    final size = small ? 20.0 : 28.0;
    final fontSize = small ? 10.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 2,
          height: size * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black87, width: 2),
            image: DecorationImage(
              image: AssetImage(AppTheme.roleImage(player.role)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          player.name,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConclusion() {
    final winnerStr = gameState.winner == Team.mafia ? 'المافيا' : 'المواطنون';
    final isMafia = gameState.winner == Team.mafia;
    
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMafia ? const Color(0xFF8B0000).withValues(alpha: 0.1) : const Color(0xFF00008B).withValues(alpha: 0.1),
        border: Border.all(color: isMafia ? const Color(0xFF8B0000) : const Color(0xFF00008B), width: 3),
      ),
      child: Column(
        children: [
          Text(
            isMafia ? '🩸' : '🕊️',
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            'النتيجة النهائية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isMafia ? const Color(0xFF8B0000) : const Color(0xFF00008B),
            ),
          ),
          Text(
            'انتصار ساحق لـ $winnerStr!',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isMafia ? const Color(0xFF8B0000) : const Color(0xFF00008B),
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
