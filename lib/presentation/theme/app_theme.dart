import 'package:flutter/material.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';

class AppTheme {
  // ─── Colors ────────────────────────────────────────────────────────────────
  static Color background    = Color(0xFF0F172A); // Deep slate
  static Color surface       = Color(0xFF1E293B);
  static Color surfaceHigh   = Color(0xFF334155);
  
  static Color accent = Color(0xFF8B5CF6); // Rich purple for neutral/GM actions
  static Color textPrimary = Color(0xFFF8FAFC);
  static Color textSecondary = Color(0xFF94A3B8);

  // Mafia team colors (Blood Red / Crimson)
  static Color mafiaPrimary = Color(0xFFE11D48);
  static Color mafiaAccent = Color(0xFF9F1239);
  
  // Citizen team colors (Cyan / Blue)
  static Color citizensPrimary = Color(0xFF0EA5E9);
  static Color citizensAccent = Color(0xFF0284C7);

  // Status colors
  static Color error = Color(0xFFEF4444);
  static Color success = Color(0xFF22C55E);
  static Color warning = Color(0xFFF59E0B);
  static Color death = Color(0xFF64748B); // Slate 500


  // Reusable Gradients for absolute masterpiece look
  static LinearGradient mafiaGradient = LinearGradient(
    colors: [mafiaPrimary, mafiaAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient citizenGradient = LinearGradient(
    colors: [citizensPrimary, citizensAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );




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
    
    specialAction = accent;
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
  }

  static ThemeData getTheme(String themeId) {
    applyTheme(themeId); // Ensure variables are updated before returning ThemeData

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
      textTheme: TextTheme(
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

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      fontFamily: 'Cairo',
      textTheme: TextTheme(
        displayLarge:  TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: textPrimary),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge:    TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge:     TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium:    TextStyle(fontSize: 14, color: textSecondary),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: textPrimary,
          elevation: 8,
          shadowColor: accent.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: surfaceHigh, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: surfaceHigh, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // --- Helper Methods for UI ---

  static Color specialAction = accent;

  static Color teamColor(Role role) {
    if (role.team == Team.mafia) return mafiaPrimary;
    if (role.team == Team.independent) return Colors.purpleAccent;
    return citizensPrimary;
  }

  static Color roleColor(Role role) {
    if (role.team == Team.mafia) return mafiaPrimary;
    if (role.team == Team.independent) return Colors.purpleAccent;
    if (role == Role.goodCitizen) return citizensPrimary;
    return specialAction;
  }

  static Map<Role, String> customRoleNames = {};

  static String roleArabicName(Role role) {
    if (customRoleNames.containsKey(role) && customRoleNames[role]!.trim().isNotEmpty) {
      return customRoleNames[role]!;
    }
    switch (role) {
      case Role.mafiaSheikh:    return 'شيخ المافيا';
      case Role.mafiaGirl:      return 'بنت المافيا';
      case Role.normalMafia:    return 'مافيا عادي';
      case Role.citizensSheikh: return 'شيخ المواطنين';
      case Role.citizensGirl:   return 'بنت المواطنين';
      case Role.citizensBoy:    return 'مواطن شجاع';
      case Role.goodCitizen:    return 'مواطن صالح';
      case Role.joker:          return 'المهرج (الجوكر)';
    }
  }

  static String roleAbilityDescription(Role role) {
    switch (role) {
      case Role.mafiaSheikh:    return 'يختار ضحية الليل';
      case Role.mafiaGirl:      return 'تصمّت لاعباً لدورة';
      case Role.normalMafia:    return 'يشارك في قرار المافيا';
      case Role.citizensSheikh: return 'يكشف هوية لاعب';
      case Role.citizensGirl:   return 'تحمي لاعباً من القتل';
      case Role.citizensBoy:    return 'ينتقم عند إقصائه';
      case Role.goodCitizen:    return 'يصوّت في النهار';
      case Role.joker:          return 'يفوز إذا تم إقصاؤه بالتصويت';
    }
  }

  static IconData roleIcon(Role role) {
    switch (role) {
      case Role.mafiaSheikh: return Icons.account_circle;
      case Role.mafiaGirl: return Icons.favorite;
      case Role.normalMafia: return Icons.local_fire_department;
      case Role.citizensSheikh: return Icons.search;
      case Role.citizensGirl: return Icons.health_and_safety;
      case Role.citizensBoy: return Icons.bolt;
      case Role.goodCitizen: return Icons.person;
      case Role.joker: return Icons.theater_comedy;
    }
  }

  static String roleImage(Role role) {
    switch (role) {
      case Role.mafiaSheikh: return 'assets/images/mafia_sheikh.jpg';
      case Role.mafiaGirl: return 'assets/images/mafia_girl.jpg';
      case Role.normalMafia: return 'assets/images/normal_mafia.jpg';
      case Role.citizensSheikh: return 'assets/images/citizens_sheikh.jpg';
      case Role.citizensGirl: return 'assets/images/citizens_girl.jpg';
      case Role.citizensBoy: return 'assets/images/citizens_boy.jpg';
      case Role.goodCitizen: return 'assets/images/good_citizen.jpg';
      case Role.joker: return 'assets/images/joker.jpg';
    }
  }
}
