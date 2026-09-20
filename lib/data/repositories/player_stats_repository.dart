import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/entities/player_stats.dart';

class PlayerStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<List<PlayerStats>> loadStats() async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('stats')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PlayerStats(
          name: data['name'] as String? ?? doc.id,
          gamesPlayed: data['gamesPlayed'] as int? ?? 0,
          mafiaWins: data['mafiaWins'] as int? ?? 0,
          citizenWins: data['citizenWins'] as int? ?? 0,
          killedFirstNight: data['killedFirstNight'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Error loading stats: $e');
      return [];
    }
  }

  Future<void> saveStats(List<PlayerStats> stats) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final batch = _firestore.batch();
      final statsCollection = _firestore.collection('users').doc(uid).collection('stats');

      for (final stat in stats) {
        final docRef = statsCollection.doc(stat.name);
        batch.set(docRef, {
          'name': stat.name,
          'gamesPlayed': stat.gamesPlayed,
          'mafiaWins': stat.mafiaWins,
          'citizenWins': stat.citizenWins,
          'killedFirstNight': stat.killedFirstNight,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error saving stats: $e');
    }
  }

  Future<void> updateStatsForPlayer(
    String name, {
    bool played = false,
    bool wonAsMafia = false,
    bool wonAsCitizen = false,
    bool diedFirstNight = false,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final docRef = _firestore.collection('users').doc(uid).collection('stats').doc(name);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final data = snapshot.data()!;
          transaction.update(docRef, {
            'gamesPlayed': (data['gamesPlayed'] as int? ?? 0) + (played ? 1 : 0),
            'mafiaWins': (data['mafiaWins'] as int? ?? 0) + (wonAsMafia ? 1 : 0),
            'citizenWins': (data['citizenWins'] as int? ?? 0) + (wonAsCitizen ? 1 : 0),
            'killedFirstNight': (data['killedFirstNight'] as int? ?? 0) + (diedFirstNight ? 1 : 0),
          });
        } else {
          transaction.set(docRef, {
            'name': name,
            'gamesPlayed': played ? 1 : 0,
            'mafiaWins': wonAsMafia ? 1 : 0,
            'citizenWins': wonAsCitizen ? 1 : 0,
            'killedFirstNight': diedFirstNight ? 1 : 0,
          });
        }
      });
    } catch (e) {
      // ignore
    }
  }
}

final playerStatsRepoProvider = Provider<PlayerStatsRepository>((ref) {
  return PlayerStatsRepository();
});
