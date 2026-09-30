import re

with open('lib/presentation/night/night_summary_screen.dart', 'r') as f:
    content = f.read()

old_logic_build = """    final summaryEvent = state.eventHistory
        .where((e) => e.type == EventType.nightResolutionSummary)
        .lastOrNull;

    final assassinatedIds =
        (summaryEvent?.metadata['assassinatedIds'] as List?)?.cast<String>() ??
            [];
    final silencedIds =
        (summaryEvent?.metadata['silencedIds'] as List?)?.cast<String>() ?? [];
    final successfulProtections = (summaryEvent
                ?.metadata['successfulProtections'] as List?)
            ?.cast<String>() ??
        [];"""

new_logic_build = """    final summaryEvent = state.eventHistory
        .where((e) => e.type == EventType.nightResolutionSummary)
        .lastOrNull;

    final mafiaDeadIds = (summaryEvent?.metadata['mafiaDeadIds'] as List?)?.cast<String>() ?? [];
    final sniperDeadIds = (summaryEvent?.metadata['sniperDeadIds'] as List?)?.cast<String>() ?? [];
    final silencedIds = (summaryEvent?.metadata['silencedIds'] as List?)?.cast<String>() ?? [];
    
    final protectedFromMafiaIds = (summaryEvent?.metadata['protectedFromMafiaIds'] as List?)?.cast<String>() ?? [];
    final protectedFromSniperIds = (summaryEvent?.metadata['protectedFromSniperIds'] as List?)?.cast<String>() ?? [];
    
    // Check if the doctor protected someone who was not targeted
    final protectedIds = (summaryEvent?.metadata['protectedIds'] as List?)?.cast<String>() ?? [];
    final nonTargetedProtections = protectedIds.where((id) => !protectedFromMafiaIds.contains(id) && !protectedFromSniperIds.contains(id)).toList();
    """

content = content.replace(old_logic_build, new_logic_build)

old_ui = """                            if (successfulProtections.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.greenAccent.withValues(alpha: 0.5),
                                      width: 2),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.shield_moon,
                                        color: Colors.greenAccent, size: 40),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                          'بنت المواطنين حمت الهدف بنجاح! لم يُقتل أحد.',
                                          style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo')),
                                    ),
                                  ],
                                ),
                              ),
                            if (assassinatedIds.isNotEmpty)
                              ...assassinatedIds.map((id) {"""

new_ui = """                            if (protectedFromMafiaIds.isNotEmpty)
                              ...protectedFromMafiaIds.map((id) {
                                final player = state.getPlayerById(id);
                                return _buildProtectionCard('حمت ${player?.name ?? ''} من اغتيال المافيا!', Colors.greenAccent);
                              }),
                            if (protectedFromSniperIds.isNotEmpty)
                              ...protectedFromSniperIds.map((id) {
                                final player = state.getPlayerById(id);
                                return _buildProtectionCard('حمت ${player?.name ?? ''} من قنص القناص!', Colors.tealAccent);
                              }),
                            if (mafiaDeadIds.isNotEmpty)
                              ...mafiaDeadIds.map((id) {
                                return _buildDeathCard(state, id, 'ضحية الليل (تم اغتياله):', Colors.redAccent);
                              }),
                            if (sniperDeadIds.isNotEmpty)
                              ...sniperDeadIds.map((id) {
                                return _buildDeathCard(state, id, 'ضحية الليل (تم قنصه):', Colors.orangeAccent);
                              }),"""

content = content.replace(old_ui, new_ui)

# Add helper methods inside _NightSummaryScreenState if not exists
helper_methods = """  Widget _buildProtectionCard(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_moon, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildDeathCard(GameState state, String id, String title, Color color) {
    final player = state.getPlayerById(id);
    if (player == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.roleColor(player.role).withValues(alpha: 0.5),
            width: 2),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo')),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.roleColor(player.role), width: 3),
            ),
            child: ClipOval(
              child: Image.asset(
                AppTheme.roleImage(player.role),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            player.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo'),
          ),
          Text(
            AppTheme.roleArabicName(player.role),
            style: TextStyle(
                color: AppTheme.roleColor(player.role),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }
"""

old_helper_replacement = """                                AppTheme.roleArabicName(player.role),
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                        );
                      }),"""

content = content.replace(old_helper_replacement, "")

content = content.replace("  Widget build(BuildContext context) {", helper_methods + "\n  @override\n  Widget build(BuildContext context) {")

with open('lib/presentation/night/night_summary_screen.dart', 'w') as f:
    f.write(content)
