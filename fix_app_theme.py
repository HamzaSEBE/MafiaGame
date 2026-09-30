import re

with open('lib/presentation/theme/app_theme.dart', 'r') as f:
    content = f.read()

# 1. Remove const from static colors
content = re.sub(r'static const Color (background|surface|surfaceHigh|accent|textPrimary|textSecondary|mafiaPrimary|mafiaAccent|citizensPrimary|citizensAccent|error|success|warning|death|specialAction)', r'static Color \1', content)

# 2. Remove const from Gradients
content = re.sub(r'static const LinearGradient (mafiaGradient|citizenGradient|backgroundGradient)', r'static LinearGradient \1', content)

# 3. Inject applyTheme method right before getTheme
apply_theme_code = """
  static void applyTheme(String themeId) {
    switch (themeId) {
      case 'midnight_blue':
        background = const Color(0xFF0A1118);
        surface = const Color(0xFF1E293B);
        surfaceHigh = const Color(0xFF334155);
        accent = const Color(0xFF0EA5E9);
        backgroundGradient = const LinearGradient(
          colors: [Color(0xFF0A1118), Color(0xFF020617)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case 'emerald_shadow':
        background = const Color(0xFF00120B);
        surface = const Color(0xFF00251A);
        surfaceHigh = const Color(0xFF004D40);
        accent = const Color(0xFF10B981);
        backgroundGradient = const LinearGradient(
          colors: [Color(0xFF00120B), Color(0xFF000503)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case 'royal_gold':
        background = const Color(0xFF1A1500);
        surface = const Color(0xFF332A00);
        surfaceHigh = const Color(0xFF4D4000);
        accent = const Color(0xFFFFD700);
        backgroundGradient = const LinearGradient(
          colors: [Color(0xFF1A1500), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case 'dark_blood':
      default:
        background = const Color(0xFF0F172A);
        surface = const Color(0xFF1E293B);
        surfaceHigh = const Color(0xFF334155);
        accent = const Color(0xFF8B0000); // Dark red instead of purple
        backgroundGradient = const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
    }
    
    // specialAction is usually same as accent
    specialAction = accent;
  }

  static ThemeData getTheme(String themeId) {
    applyTheme(themeId); // Ensure variables are updated before returning ThemeData
"""

content = content.replace("  static ThemeData getTheme(String themeId) {", apply_theme_code)

with open('lib/presentation/theme/app_theme.dart', 'w') as f:
    f.write(content)

