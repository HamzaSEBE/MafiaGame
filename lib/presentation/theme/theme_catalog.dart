import 'package:flutter/material.dart';

/// One source of truth for theme tokens and their gallery presentation.
@immutable
class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.name,
    required this.englishName,
    required this.description,
    required this.mood,
    required this.background,
    required this.backgroundEnd,
    required this.surface,
    required this.surfaceHigh,
    required this.accent,
    required this.companion,
    required this.cardStart,
    required this.cardEnd,
    required this.textSecondary,
    required this.icon,
    this.isPremium = true,
  });

  static const schemaVersion = 1;
  final String id;
  int get version => schemaVersion;
  String? get requiredFeature => isPremium ? 'themes' : null;
  final String name;
  final String englishName;
  final String description;
  final String mood;
  final Color background;
  final Color backgroundEnd;
  final Color surface;
  final Color surfaceHigh;
  final Color accent;
  final Color companion;
  final Color cardStart;
  final Color cardEnd;
  final Color textSecondary;
  final IconData icon;
  final bool isPremium;

  Color get textPrimary => const Color(0xFFF8F6F2);
  List<Color> get swatches => [accent, companion, surfaceHigh, background];
  LinearGradient get backgroundGradient => LinearGradient(
    colors: [background, backgroundEnd],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
  LinearGradient get actionGradient => LinearGradient(
    colors: [cardStart, cardEnd],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}

abstract final class ThemeCatalog {
  static const defaultId = 'dark_blood';

  static const themes = <ThemePalette>[
    ThemePalette(
      id: defaultId,
      name: 'الأحمر الدموي',
      englishName: 'DARK BLOOD',
      description:
          'الأحمر الدموي الغامق على خلفية ليلية. الهوية الأصلية للمافيا.',
      mood: 'درامي · كلاسيكي',
      background: Color(0xFF0F172A),
      backgroundEnd: Color(0xFF020617),
      surface: Color(0xFF1E293B),
      surfaceHigh: Color(0xFF334155),
      accent: Color(0xFF8B0000),
      companion: Color(0xFFFF5252),
      cardStart: Color(0xFF8B0000),
      cardEnd: Color(0xFF4A0000),
      textSecondary: Color(0xFFB8C4D6),
      icon: Icons.theater_comedy_outlined,
      isPremium: false,
    ),
    ThemePalette(
      id: 'midnight_blue',
      name: 'منتصف الليل',
      englishName: 'MIDNIGHT ATELIER',
      description:
          'أزرق ملكي عميق يمتزج ببنفسجي ليلي. لونان يصنعان أجواء غامضة قبل لحظة الكشف.',
      mood: 'هادئ · غامض · معاصر',
      background: Color(0xFF141229),
      backgroundEnd: Color(0xFF050B1B),
      surface: Color(0xFF24223F),
      surfaceHigh: Color(0xFF403A60),
      accent: Color(0xFF194AB5),
      companion: Color(0xFFB9A0E0),
      cardStart: Color(0xFF194AB5),
      cardEnd: Color(0xFF34174F),
      textSecondary: Color(0xFFC6BEDD),
      icon: Icons.nights_stay_outlined,
    ),
    ThemePalette(
      id: 'emerald_shadow',
      name: 'النادي الزمردي',
      englishName: 'EMERALD SOCIETY',
      description:
          'زمرد غني يلتقي بأزرق ياقوتي داكن. أجواء الصالات الخاصة وطاولات اللعب.',
      mood: 'عميق · متوازن · أنيق',
      background: Color(0xFF0E1D2B),
      backgroundEnd: Color(0xFF03130F),
      surface: Color(0xFF19323F),
      surfaceHigh: Color(0xFF315264),
      accent: Color(0xFF00624F),
      companion: Color(0xFF88BFE8),
      cardStart: Color(0xFF00624F),
      cardEnd: Color(0xFF102B56),
      textSecondary: Color(0xFFBAD5D7),
      icon: Icons.diamond_outlined,
    ),
    ThemePalette(
      id: 'royal_gold',
      name: 'الجناح الملكي',
      englishName: 'ROYAL NOIR',
      description:
          'ذهب معتّق مع بنفسجي ملكي داكن. مزيج دافئ وفخم بتدرجات واضحة وهادئة.',
      mood: 'فاخر · دافئ · ملكي',
      background: Color(0xFF1C1427),
      backgroundEnd: Color(0xFF0E0909),
      surface: Color(0xFF30243D),
      surfaceHigh: Color(0xFF51415C),
      accent: Color(0xFF79551A),
      companion: Color(0xFFC4A4E2),
      cardStart: Color(0xFF79551A),
      cardEnd: Color(0xFF36214D),
      textSecondary: Color(0xFFD5C6DC),
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  static bool contains(String id) => themes.any((theme) => theme.id == id);

  static ThemePalette byId(String id) =>
      themes.firstWhere((theme) => theme.id == id, orElse: () => themes.first);
}
