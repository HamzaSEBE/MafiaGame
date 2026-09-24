import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<Map<Role, String>> loadCustomRoleNames() async {
    try {
      final uid = _uid;
      if (uid == null) return {};

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('roleNames')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final Map<Role, String> customNames = {};
        for (final entry in data.entries) {
          final role = Role.values.firstWhere(
            (r) => r.name == entry.key,
            orElse: () => Role.goodCitizen, // Fallback if not found
          );
          if (role.name == entry.key) { // Ensure it actually matched
            customNames[role] = entry.value as String;
          }
        }
        return customNames;
      }
      return {};
    } catch (e) {
      print('Error loading custom role names: $e');
      return {};
    }
  }

  Future<void> saveCustomRoleNames(Map<Role, String> names) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final data = <String, String>{};
      for (final entry in names.entries) {
        data[entry.key.name] = entry.value;
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('roleNames')
          .set(data);
    } catch (e) {
      print('Error saving custom role names: $e');
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

