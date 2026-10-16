import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/application/premium_service.dart';
import 'package:mafia_nightfall/data/repositories/theme_preferences_repository.dart';
import 'package:mafia_nightfall/domain/entities/theme_id.dart';

class ThemeSelectionNotifier extends StateNotifier<String> {
  ThemeSelectionNotifier({
    required this.repository,
    required this.uid,
    required bool isPremium,
  }) : _isPremium = isPremium,
       super(AppThemeId.darkBlood.id) {
    _restore();
  }

  final ThemePreferencesRepository repository;
  final String? uid;
  bool _isPremium;
  AppThemeId _preferred = AppThemeId.darkBlood;
  int _revision = 0;
  bool _saving = false;

  Future<void> _restore() async {
    if (uid == null) return;
    final revision = _revision;
    try {
      final saved = await repository.load(uid!);
      if (!mounted || revision != _revision) return;
      _preferred = AppThemeId.fromId(saved ?? '') ?? AppThemeId.darkBlood;
      _applyEntitlement();
    } catch (_) {
      // Retain a usable default offline. A failed save still reaches the UI.
    }
  }

  void updateEntitlement(bool isPremium) {
    _isPremium = isPremium;
    _applyEntitlement();
  }

  void _applyEntitlement() {
    if (!mounted) return;
    state = _preferred.isPremium && !_isPremium
        ? AppThemeId.darkBlood.id
        : _preferred.id;
  }

  Future<void> selectTheme(String id) async {
    final theme = AppThemeId.fromId(id);
    if (theme == null) throw ArgumentError.value(id, 'id', 'Unknown theme');
    if (theme.isPremium && !_isPremium) {
      throw StateError('Premium is required for this theme.');
    }
    if (uid == null) throw StateError('Sign in to save a theme.');
    if (_saving) throw StateError('A theme is already being saved.');
    _saving = true;
    _revision++;
    try {
      await repository.save(uid!, id);
      if (!mounted) return;
      _preferred = theme;
      _applyEntitlement();
    } finally {
      _saving = false;
    }
  }
}

final selectedThemeProvider =
    StateNotifierProvider<ThemeSelectionNotifier, String>((ref) {
      final controller = ThemeSelectionNotifier(
        repository: ref.watch(themePreferencesRepositoryProvider),
        uid: ref.watch(accountIdProvider),
        isPremium: ref.read(premiumProvider),
      );
      ref.listen<bool>(premiumProvider, (_, value) {
        controller.updateEntitlement(value);
      });
      return controller;
    });
