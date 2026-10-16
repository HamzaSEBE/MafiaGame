/// Stable stored identifiers; presentation palettes live in the theme catalog.
enum AppThemeId {
  darkBlood('dark_blood', false),
  midnightBlue('midnight_blue', true),
  emeraldShadow('emerald_shadow', true),
  royalGold('royal_gold', true);

  const AppThemeId(this.id, this.isPremium);

  final String id;
  final bool isPremium;

  static AppThemeId? fromId(String id) {
    for (final theme in values) {
      if (theme.id == id) return theme;
    }
    return null;
  }
}
