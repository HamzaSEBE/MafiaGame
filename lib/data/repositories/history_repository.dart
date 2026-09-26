import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerRecord {
  final String name;
  final String roleName;
  final String team;

  PlayerRecord({
    required this.name,
    required this.roleName,
    required this.team,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'roleName': roleName,
        'team': team,
      };

  factory PlayerRecord.fromJson(Map<String, dynamic> json) => PlayerRecord(
        name: json['name'] as String,
        roleName: json['roleName'] as String,
        team: json['team'] as String,
      );
}

class GameRecord {
  final String id;
  final DateTime date;
  final String winningTeam;
  final List<PlayerRecord> players;
  final String newspaperText;

  GameRecord({
    required this.id,
    required this.date,
    required this.winningTeam,
    required this.players,
    required this.newspaperText,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'winningTeam': winningTeam,
        'players': players.map((p) => p.toJson()).toList(),
        'newspaperText': newspaperText,
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        winningTeam: json['winningTeam'] as String,
        players: (json['players'] as List)
            .map((p) => PlayerRecord.fromJson(p as Map<String, dynamic>))
            .toList(),
        newspaperText: json['newspaperText'] as String,
      );
}

class HistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<List<GameRecord>> getHistory() async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('games')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GameRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }

  Future<void> addGame(GameRecord game) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('games')
          .doc(game.id)
          .set(game.toJson());
    } catch (e) {
      print('Error adding game: $e');
    }
  }

  Future<void> deleteGame(String gameId) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('games')
          .doc(gameId)
          .delete();
    } catch (e) {
      print('Error deleting game: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('games')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing history: $e');
    }
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});