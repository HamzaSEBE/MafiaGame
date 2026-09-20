import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerProfilesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<List<String>> loadSavedPlayers() async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('savedPlayers')
          .doc('list')
          .get();

      if (doc.exists && doc.data()!.containsKey('names')) {
        final names = doc.data()!['names'] as List<dynamic>;
        return names.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error loading saved players: $e');
      return [];
    }
  }

  Future<void> savePlayers(List<String> players) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('savedPlayers')
          .doc('list')
          .set({'names': players});
    } catch (e) {
      print('Error saving players: $e');
    }
  }
}

final playerProfilesRepositoryProvider = Provider<PlayerProfilesRepository>((ref) {
  return PlayerProfilesRepository();
});
