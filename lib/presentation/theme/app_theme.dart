import 'package:flutter/material.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';

class AppTheme {
  // ─── Colors ────────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF0F172A); // Deep slate
  static const Color surface       = Color(0xFF1E293B);
  static const Color surfaceHigh   = Color(0xFF334155);
  
  static const Color accent = Color(0xFF8B5CF6); // Rich purple for neutral/GM actions
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  // Mafia team colors (Blood Red / Crimson)
  static const Color mafiaPrimary = Color(0xFFE11D48);
  static const Color mafiaAccent = Color(0xFF9F1239);
  
  // Citizen team colors (Cyan / Blue)
  static const Color citizensPrimary = Color(0xFF0EA5E9);
  static const Color citizensAccent = Color(0xFF0284C7);

  // Status colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color death = Color(0xFF64748B); // Slate 500


  // Reusable Gradients for absolute masterpiece look
  static const LinearGradient mafiaGradient = LinearGradient(
    colors: [mafiaPrimary, mafiaAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient citizenGradient = LinearGradient(
    colors: [citizensPrimary, citizensAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      fontFamily: 'Cairo',
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: textPrimary),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge:    TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge:     TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium:    TextStyle(fontSize: 14, color: textSecondary),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: textPrimary),
      ),
      appBarTheme: const AppBarTheme(
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
          side: const BorderSide(color: surfaceHigh, width: 2),
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
          side: const BorderSide(color: surfaceHigh, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // --- Helper Methods for UI ---

  static const Color specialAction = accent;

  static Color teamColor(Role role) {
    if (role.team == Team.mafia) return mafiaPrimary;
    return citizensPrimary;
  }

  static Color roleColor(Role role) {
    if (role.team == Team.mafia) return mafiaPrimary;
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
    }
  }
}
