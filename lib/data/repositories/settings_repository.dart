import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';

class SettingsRepository {
  SettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  Future<Map<Role, String>> loadCustomRoleNames(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('roleNames')
        .get();
    final data = doc.data() ?? {};
    return {
      for (final role in Role.values)
        if (data[role.name] is String &&
            (data[role.name] as String).trim().isNotEmpty)
          role: data[role.name] as String,
    };
  }

  Future<void> saveCustomRoleNames(String uid, Map<Role, String> names) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('roleNames')
          .set({
            for (final entry in names.entries) entry.key.name: entry.value,
          });
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);
