import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/auth_service.dart';

/// One authentication stream drives account-scoped application state.
final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final accountIdProvider = Provider<String?>((ref) {
  return ref.watch(authUserProvider).asData?.value?.uid;
});

/// Shared by entitlement and profile UI instead of opening duplicate listeners.
final accountProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(accountIdProvider);
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) => snapshot.data());
});
