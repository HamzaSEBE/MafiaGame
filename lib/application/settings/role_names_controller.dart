import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/data/repositories/settings_repository.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';

final roleNamesProvider =
    AsyncNotifierProvider<RoleNamesController, Map<Role, String>>(
      RoleNamesController.new,
    );

class RoleNamesController extends AsyncNotifier<Map<Role, String>> {
  @override
  Future<Map<Role, String>> build() async {
    final uid = ref.watch(accountIdProvider);
    if (uid == null) return {};
    return ref.watch(settingsRepositoryProvider).loadCustomRoleNames(uid);
  }

  Future<void> save(Map<Role, String> names) async {
    final uid = ref.read(accountIdProvider);
    if (uid == null) throw StateError('سجّل الدخول لحفظ أسماء الأدوار.');
    final clean = {
      for (final entry in names.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
    };
    if (clean.values.any((name) => name.length > 80)) {
      throw ArgumentError('اسم الدور لا يتجاوز 80 حرفاً.');
    }
    await ref.read(settingsRepositoryProvider).saveCustomRoleNames(uid, clean);
    if (uid == ref.read(accountIdProvider)) {
      state = AsyncData(Map.unmodifiable(clean));
    }
  }
}
