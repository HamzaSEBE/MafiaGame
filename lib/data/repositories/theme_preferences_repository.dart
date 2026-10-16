import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ThemePreferencesRepository {
  Future<String?> load(String uid);
  Future<void> save(String uid, String themeId);
}

class FirestoreThemePreferencesRepository
    implements ThemePreferencesRepository {
  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('appearance');

  @override
  Future<String?> load(String uid) async {
    final value = (await _document(uid).get()).data()?['themeId'];
    return value is String ? value : null;
  }

  @override
  Future<void> save(String uid, String themeId) {
    return _document(uid).set({'themeId': themeId}, SetOptions(merge: true));
  }
}

final themePreferencesRepositoryProvider = Provider<ThemePreferencesRepository>(
  (ref) => FirestoreThemePreferencesRepository(),
);
