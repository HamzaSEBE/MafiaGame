with open('lib/presentation/theme/app_theme.dart', 'r') as f:
    content = f.read()

# Replace static const Color background with dynamic handling
new_code = """
  static ThemeData getTheme(String themeId) {
    Color bg = const Color(0xFF07070B);
    Color primary = accent;

    switch (themeId) {
      case 'midnight_blue':
        bg = const Color(0xFF0A1118);
        primary = const Color(0xFF0EA5E9);
        break;
      case 'emerald_shadow':
        bg = const Color(0xFF00120B);
        primary = const Color(0xFF10B981);
        break;
      case 'royal_gold':
        bg = const Color(0xFF1A1500);
        primary = const Color(0xFFFFD700);
        break;
      case 'dark_blood':
      default:
        bg = const Color(0xFF07070B);
        primary = const Color(0xFF8B0000);
        break;
    }

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      fontFamily: 'Cairo',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: textPrimary),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: textPrimary),
      ),
    );
  }
"""

content = content.replace("  static ThemeData get darkTheme {", new_code + "\n  static ThemeData get darkTheme {")

with open('lib/presentation/theme/app_theme.dart', 'w') as f:
    f.write(content)
