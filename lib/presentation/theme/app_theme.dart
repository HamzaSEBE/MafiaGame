import 'package:flutter/material.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';

class AppTheme {
  // Gameplay meaning must remain recognizable in every cosmetic theme.
  static const Color mafiaPrimary = Color(0xFFEF4444);
  static const Color mafiaAccent = Color(0xFF8B0000);
  static const Color citizensPrimary = Color(0xFF7DD3FC);
  static const Color citizensAccent = Color(0xFF0369A1);
  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color death = Color(0xFF94A3B8);
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

  static ThemeData getTheme(
    String themeId, {
    Map<Role, String> roleNames = const {},
  }) => _buildTheme(ThemeCatalog.byId(themeId), roleNames: roleNames);
  static ThemeData previewTheme(ThemePalette palette) => _buildTheme(palette);
  static ThemeData get darkTheme => _buildTheme(ThemeCatalog.themes.first);

  static ThemeData _buildTheme(
    ThemePalette palette, {
    Map<Role, String> roleNames = const {},
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: palette.accent,
          primaryContainer: palette.cardEnd,
          onPrimaryContainer: palette.textPrimary,
          primaryFixed: palette.cardStart,
          primaryFixedDim: palette.cardEnd,
          onPrimaryFixed: palette.textPrimary,
          onPrimaryFixedVariant: palette.textPrimary,
          secondaryFixed: palette.surfaceHigh,
          secondaryFixedDim: palette.surface,
          onSecondaryFixed: palette.textPrimary,
          onSecondaryFixedVariant: palette.textPrimary,
          tertiaryFixed: palette.cardStart,
          tertiaryFixedDim: palette.cardEnd,
          onTertiaryFixed: palette.textPrimary,
          onTertiaryFixedVariant: palette.textPrimary,
          inversePrimary: palette.companion,
          onPrimary: palette.accent.computeLuminance() > .3
              ? palette.backgroundEnd
              : palette.textPrimary,
          secondary: palette.companion,
          onSecondary: palette.backgroundEnd,
          secondaryContainer: palette.surfaceHigh,
          onSecondaryContainer: palette.textPrimary,
          tertiary: palette.companion,
          onTertiary: palette.backgroundEnd,
          tertiaryContainer: palette.cardEnd,
          onTertiaryContainer: palette.textPrimary,
          surface: palette.surface,
          surfaceDim: palette.backgroundEnd,
          surfaceBright: palette.surfaceHigh,
          surfaceContainerLowest: palette.backgroundEnd,
          surfaceContainerLow: palette.background,
          surfaceContainer: palette.surface,
          surfaceContainerHigh: palette.surface,
          surfaceContainerHighest: palette.surfaceHigh,
          surfaceTint: Colors.transparent,
          onSurface: palette.textPrimary,
          onSurfaceVariant: palette.textSecondary,
          error: error,
          onError: palette.backgroundEnd,
          errorContainer: const Color(0xFF450A0A),
          onErrorContainer: palette.textPrimary,
          outline: palette.textSecondary,
          outlineVariant: palette.surfaceHigh,
          inverseSurface: palette.textPrimary,
          onInverseSurface: palette.backgroundEnd,
        );
    return ThemeData(
      useMaterial3: true,
      extensions: [
        GameVisualTokens(palette),
        RoleLabels(Map.unmodifiable(roleNames)),
      ],
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      primaryColor: palette.accent,
      colorScheme: scheme,
      fontFamily: 'Cairo',
      dividerColor: palette.surfaceHigh,
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: palette.surfaceHigh),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15,
          height: 1.7,
          color: palette.textSecondary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.companion,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        floatingLabelStyle: TextStyle(color: palette.companion),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.surfaceHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.companion, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.companion,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.companion
              : palette.textSecondary,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(palette.textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.companion
              : palette.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.cardEnd
              : palette.surfaceHigh,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceHigh,
        contentTextStyle: TextStyle(
          color: palette.textPrimary,
          fontFamily: 'Cairo',
        ),
        actionTextColor: palette.companion,
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: palette.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: palette.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: palette.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.accent.computeLuminance() > .3
              ? palette.backgroundEnd
              : palette.textPrimary,
          elevation: 0,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.surfaceHigh),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: palette.surfaceHigh),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  // --- Helper Methods for UI ---

  static Color teamColor(Role role) {
    if (role.team == Team.mafia) return mafiaPrimary;
    if (role.team == Team.independent) return Colors.purpleAccent;
    return citizensPrimary;
  }

  static Color roleColor(Role role) {
    if (role.team == Team.mafia) return mafiaPrimary;
    if (role.team == Team.independent) return Colors.purpleAccent;
    if (role == Role.goodCitizen) return Colors.white;
    return citizensPrimary;
  }

  static String roleArabicName(Role role) {
    switch (role) {
      case Role.mafiaSheikh:
        return 'شيخ المافيا';
      case Role.mafiaGirl:
        return 'بنت المافيا';
      case Role.normalMafia:
        return 'مافيا عادي';
      case Role.citizensSheikh:
        return 'شيخ المواطنين';
      case Role.citizensGirl:
        return 'بنت المواطنين';
      case Role.citizensBoy:
        return 'مواطن شجاع';
      case Role.goodCitizen:
        return 'مواطن صالح';
      case Role.joker:
        return 'المهرج (الجوكر)';
    }
  }

  static String roleAbilityDescription(Role role) {
    switch (role) {
      case Role.mafiaSheikh:
        return 'يختار ضحية الليل';
      case Role.mafiaGirl:
        return 'تصمّت لاعباً لدورة';
      case Role.normalMafia:
        return 'يشارك في قرار المافيا';
      case Role.citizensSheikh:
        return 'يكشف هوية لاعب';
      case Role.citizensGirl:
        return 'تحمي لاعباً من القتل';
      case Role.citizensBoy:
        return 'ينتقم عند إقصائه';
      case Role.goodCitizen:
        return 'يصوّت في النهار';
      case Role.joker:
        return 'يفوز إذا تم إقصاؤه بالتصويت';
    }
  }

  static IconData roleIcon(Role role) {
    switch (role) {
      case Role.mafiaSheikh:
        return Icons.account_circle;
      case Role.mafiaGirl:
        return Icons.favorite;
      case Role.normalMafia:
        return Icons.local_fire_department;
      case Role.citizensSheikh:
        return Icons.search;
      case Role.citizensGirl:
        return Icons.health_and_safety;
      case Role.citizensBoy:
        return Icons.bolt;
      case Role.goodCitizen:
        return Icons.person;
      case Role.joker:
        return Icons.theater_comedy;
    }
  }

  static String roleImage(Role role) {
    switch (role) {
      case Role.mafiaSheikh:
        return 'assets/images/mafia_sheikh.jpg';
      case Role.mafiaGirl:
        return 'assets/images/mafia_girl.jpg';
      case Role.normalMafia:
        return 'assets/images/normal_mafia.jpg';
      case Role.citizensSheikh:
        return 'assets/images/citizens_sheikh.jpg';
      case Role.citizensGirl:
        return 'assets/images/citizens_girl.jpg';
      case Role.citizensBoy:
        return 'assets/images/citizens_boy.jpg';
      case Role.goodCitizen:
        return 'assets/images/good_citizen.jpg';
      case Role.joker:
        return 'assets/images/joker.jpg';
    }
  }
}

/// Immutable, scoped decoration. Semantic role/team colors remain in AppTheme.
@immutable
class GameVisualTokens extends ThemeExtension<GameVisualTokens> {
  const GameVisualTokens(this.palette);
  final ThemePalette palette;
  Color get background => palette.background;
  Color get surface => palette.surface;
  Color get surfaceHigh => palette.surfaceHigh;
  Color get accent => palette.accent;
  Color get textPrimary => palette.textPrimary;
  Color get textSecondary => palette.textSecondary;
  LinearGradient get backgroundGradient => palette.backgroundGradient;
  Color get primaryCardStart => palette.cardStart;
  Color get primaryCardEnd => palette.cardEnd;
  Color get secondaryCardStart => palette.companion;
  Color get secondaryCardEnd => palette.cardEnd;
  Color get glowColor => palette.accent;
  Color get borderHighlight => palette.accent;
  Color get iconColor1 => palette.accent;
  Color get iconColor2 => palette.companion;
  Color get iconColor3 => palette.textSecondary;
  Color get specialAction => palette.accent;
  @override
  GameVisualTokens copyWith({ThemePalette? palette}) =>
      GameVisualTokens(palette ?? this.palette);
  @override
  GameVisualTokens lerp(covariant GameVisualTokens? other, double t) =>
      t < .5 ? this : other ?? this;
}

extension GameThemeContext on BuildContext {
  String roleName(Role role) =>
      Theme.of(this).extension<RoleLabels>()?.names[role] ??
      AppTheme.roleArabicName(role);
  GameVisualTokens get visual =>
      Theme.of(this).extension<GameVisualTokens>() ??
      GameVisualTokens(ThemeCatalog.themes.first);
}

@immutable
class RoleLabels extends ThemeExtension<RoleLabels> {
  const RoleLabels(this.names);
  final Map<Role, String> names;
  @override
  RoleLabels copyWith({Map<Role, String>? names}) =>
      RoleLabels(Map.unmodifiable(names ?? this.names));
  @override
  RoleLabels lerp(covariant RoleLabels? other, double t) =>
      t < .5 ? this : other ?? this;
}
