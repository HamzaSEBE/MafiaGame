import re

with open('lib/presentation/night/night_summary_screen.dart', 'r') as f:
    content = f.read()

# I will just extract the whole file and fix the position of these methods
# First remove them from wherever they are
helper_methods_re = r'  Widget _buildProtectionCard\(String text, Color color\) \{.*?\n  \}\n\n  Widget _buildDeathCard\(GameState state, String id, String title, Color color\) \{.*?\n  \}\n'
content = re.sub(helper_methods_re, '', content, flags=re.DOTALL)
content = content.replace('  @override\n  @override\n', '  @override\n')

# Now add them inside _NightSummaryScreenState before _goToDay
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

content = content.replace("  void _goToDay() {", helper_methods + "  void _goToDay() {")

with open('lib/presentation/night/night_summary_screen.dart', 'w') as f:
    f.write(content)
