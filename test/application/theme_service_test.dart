import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/data/repositories/theme_preferences_repository.dart';

class MemoryThemePreferences implements ThemePreferencesRepository {
  String? value;
  Completer<String?>? pendingLoad;
  Completer<void>? pendingSave;
  bool failSave = false;
  final List<String> writes = [];

  @override
  Future<String?> load(String uid) async =>
      pendingLoad == null ? value : await pendingLoad!.future;

  @override
  Future<void> save(String uid, String themeId) async {
    if (failSave) throw StateError('offline');
    if (pendingSave != null) await pendingSave!.future;
    writes.add('$uid:$themeId');
    value = themeId;
  }
}

void main() {
  test(
    'restores preference but applies premium palette only with entitlement',
    () async {
      final repo = MemoryThemePreferences()..value = 'royal_gold';
      final controller = ThemeSelectionNotifier(
        repository: repo,
        uid: 'a',
        isPremium: false,
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, 'dark_blood');
      controller.updateEntitlement(true);
      expect(controller.state, 'royal_gold');
      controller.updateEntitlement(false);
      expect(controller.state, 'dark_blood');
      expect(repo.writes, isEmpty);
    },
  );

  test('denies locked and unknown themes without persisting', () async {
    final repo = MemoryThemePreferences();
    final controller = ThemeSelectionNotifier(
      repository: repo,
      uid: 'a',
      isPremium: false,
    );
    addTearDown(controller.dispose);
    await expectLater(controller.selectTheme('royal_gold'), throwsStateError);
    await expectLater(controller.selectTheme('invalid'), throwsArgumentError);
    expect(repo.writes, isEmpty);
  });

  test('a failed save preserves the applied theme', () async {
    final repo = MemoryThemePreferences()..value = 'midnight_blue';
    final controller = ThemeSelectionNotifier(
      repository: repo,
      uid: 'a',
      isPremium: true,
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);
    repo.failSave = true;
    await expectLater(controller.selectTheme('royal_gold'), throwsStateError);
    expect(controller.state, 'midnight_blue');
  });

  test('late restore cannot overwrite an explicit selection', () async {
    final repo = MemoryThemePreferences()..pendingLoad = Completer<String?>();
    final controller = ThemeSelectionNotifier(
      repository: repo,
      uid: 'a',
      isPremium: true,
    );
    addTearDown(controller.dispose);
    await controller.selectTheme('emerald_shadow');
    repo.pendingLoad!.complete('royal_gold');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, 'emerald_shadow');
    expect(repo.writes, ['a:emerald_shadow']);
  });

  test(
    'revoking access during save never activates a premium palette',
    () async {
      final repo = MemoryThemePreferences()..pendingSave = Completer<void>();
      final controller = ThemeSelectionNotifier(
        repository: repo,
        uid: 'a',
        isPremium: true,
      );
      addTearDown(controller.dispose);
      final saving = controller.selectTheme('royal_gold');
      controller.updateEntitlement(false);
      repo.pendingSave!.complete();
      await saving;
      expect(controller.state, 'dark_blood');
    },
  );

  test('parallel saves cannot reorder the persisted selection', () async {
    final repo = MemoryThemePreferences()..pendingSave = Completer<void>();
    final controller = ThemeSelectionNotifier(
      repository: repo,
      uid: 'a',
      isPremium: true,
    );
    addTearDown(controller.dispose);
    final saving = controller.selectTheme('royal_gold');
    await expectLater(
      controller.selectTheme('midnight_blue'),
      throwsStateError,
    );
    repo.pendingSave!.complete();
    await saving;
    expect(controller.state, 'royal_gold');
  });

  test(
    'disposing account controller ignores late restore and save callbacks',
    () async {
      final repo = MemoryThemePreferences()..pendingLoad = Completer<String?>();
      final controller = ThemeSelectionNotifier(
        repository: repo,
        uid: 'old',
        isPremium: true,
      );
      controller.dispose();
      repo.pendingLoad!.complete('royal_gold');
      await Future<void>.delayed(Duration.zero);
      final next = ThemeSelectionNotifier(
        repository: MemoryThemePreferences(),
        uid: 'new',
        isPremium: false,
      );
      addTearDown(next.dispose);
      expect(next.state, 'dark_blood');
    },
  );
}
