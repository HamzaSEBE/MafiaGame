import re

with open('lib/presentation/theme/app_theme.dart', 'r') as f:
    content = f.read()

# Add new semantic color variables
new_vars = """
  // Semantic UI Colors
  static Color primaryCardStart = const Color(0xFF8B0000);
  static Color primaryCardEnd = const Color(0xFF4A0000);
  
  static Color secondaryCardStart = Colors.purpleAccent;
  static Color secondaryCardEnd = Colors.deepPurple;
  
  static Color glowColor = const Color(0xFF8B0000);
  static Color borderHighlight = Colors.redAccent;
  
  static Color iconColor1 = Colors.redAccent;
  static Color iconColor2 = Colors.amber;
  static Color iconColor3 = Colors.blueAccent;
"""

# Inject before applyTheme
content = content.replace("  static void applyTheme(String themeId) {", new_vars + "\n  static void applyTheme(String themeId) {")

# Update applyTheme to set these variables
apply_theme_logic_old = """
  static void applyTheme(String themeId) {
    switch (themeId) {
      case 'midnight_blue':
        background = const Color(0xFF0A1118);
        surface = const Color(0xFF1E293B);
        surfaceHigh = const Color(0xFF334155);
        accent = const Color(0xFF0EA5E9);
        backgroundGradient = LinearGradient(
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
        backgroundGradient = LinearGradient(
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
        backgroundGradient = LinearGradient(
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
        backgroundGradient = LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
    }
"""

apply_theme_logic_new = """
  static void applyTheme(String themeId) {
    switch (themeId) {
      case 'midnight_blue':
        background = const Color(0xFF050B14);
        surface = const Color(0xFF0F172A);
        surfaceHigh = const Color(0xFF1E293B);
        accent = const Color(0xFF0EA5E9);
        backgroundGradient = LinearGradient(
          colors: [Color(0xFF050B14), Color(0xFF020408)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        primaryCardStart = const Color(0xFF0284C7);
        primaryCardEnd = const Color(0xFF0369A1);
        secondaryCardStart = const Color(0xFF38BDF8);
        secondaryCardEnd = const Color(0xFF0284C7);
        glowColor = const Color(0xFF0EA5E9);
        borderHighlight = const Color(0xFF38BDF8);
        iconColor1 = const Color(0xFF38BDF8);
        iconColor2 = const Color(0xFF7DD3FC);
        iconColor3 = const Color(0xFFBAE6FD);
        
        // Update Mafia/Citizen colors slightly to match theme
        mafiaPrimary = const Color(0xFF0284C7);
        mafiaAccent = const Color(0xFF0369A1);
        citizensPrimary = const Color(0xFF38BDF8);
        citizensAccent = const Color(0xFF0EA5E9);
        break;
      case 'emerald_shadow':
        background = const Color(0xFF000A05);
        surface = const Color(0xFF001A0D);
        surfaceHigh = const Color(0xFF00331A);
        accent = const Color(0xFF10B981);
        backgroundGradient = LinearGradient(
          colors: [Color(0xFF000A05), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        primaryCardStart = const Color(0xFF059669);
        primaryCardEnd = const Color(0xFF047857);
        secondaryCardStart = const Color(0xFF34D399);
        secondaryCardEnd = const Color(0xFF059669);
        glowColor = const Color(0xFF10B981);
        borderHighlight = const Color(0xFF34D399);
        iconColor1 = const Color(0xFF34D399);
        iconColor2 = const Color(0xFF6EE7B7);
        iconColor3 = const Color(0xFFA7F3D0);
        
        mafiaPrimary = const Color(0xFF059669);
        mafiaAccent = const Color(0xFF047857);
        citizensPrimary = const Color(0xFF34D399);
        citizensAccent = const Color(0xFF10B981);
        break;
      case 'royal_gold':
        background = const Color(0xFF0A0800);
        surface = const Color(0xFF1A1500);
        surfaceHigh = const Color(0xFF332A00);
        accent = const Color(0xFFFFD700);
        backgroundGradient = LinearGradient(
          colors: [Color(0xFF0A0800), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        primaryCardStart = const Color(0xFFB8860B);
        primaryCardEnd = const Color(0xFF8B6508);
        secondaryCardStart = const Color(0xFFFFD700);
        secondaryCardEnd = const Color(0xFFDAA520);
        glowColor = const Color(0xFFFFD700);
        borderHighlight = const Color(0xFFFFE066);
        iconColor1 = const Color(0xFFFFD700);
        iconColor2 = const Color(0xFFFFE066);
        iconColor3 = const Color(0xFFFFF0B3);
        
        mafiaPrimary = const Color(0xFFB8860B);
        mafiaAccent = const Color(0xFF8B6508);
        citizensPrimary = const Color(0xFFFFD700);
        citizensAccent = const Color(0xFFDAA520);
        break;
      case 'dark_blood':
      default:
        background = const Color(0xFF0F172A);
        surface = const Color(0xFF1E293B);
        surfaceHigh = const Color(0xFF334155);
        accent = const Color(0xFF8B0000);
        backgroundGradient = LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        primaryCardStart = const Color(0xFF8B0000);
        primaryCardEnd = const Color(0xFF4A0000);
        secondaryCardStart = Colors.purpleAccent;
        secondaryCardEnd = Colors.deepPurple;
        glowColor = const Color(0xFF8B0000);
        borderHighlight = Colors.redAccent;
        iconColor1 = Colors.redAccent;
        iconColor2 = Colors.amber;
        iconColor3 = Colors.blueAccent;
        
        mafiaPrimary = const Color(0xFFE11D48);
        mafiaAccent = const Color(0xFF9F1239);
        citizensPrimary = const Color(0xFF0EA5E9);
        citizensAccent = const Color(0xFF0284C7);
        break;
    }
    
    // Update team gradients based on the new primary/accent colors
    mafiaGradient = LinearGradient(
      colors: [mafiaPrimary, mafiaAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    citizenGradient = LinearGradient(
      colors: [citizensPrimary, citizensAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
"""

# Replace the switch block. To do this safely, we will replace everything from `static void applyTheme` to `specialAction = accent;`
content = re.sub(r'static void applyTheme\(String themeId\) \{.*?\specialAction = accent;\n  \}', apply_theme_logic_new + '\n    specialAction = accent;\n  }', content, flags=re.DOTALL)

with open('lib/presentation/theme/app_theme.dart', 'w') as f:
    f.write(content)

