import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/entities/player_stats.dart';

/// Keep existing valid keys while encoding names that are not document IDs.
String playerStatsDocumentId(String name) {
  const prefix = '__encoded__';
  if (name.isEmpty ||
      name == '.' ||
      name == '..' ||
      name.contains('/') ||
      name.startsWith(prefix)) {
    return '$prefix${base64Url.encode(utf8.encode(name))}';
  }
  return name;
}

class StatsPage {
  const StatsPage(this.players, {this.cursor, required this.hasMore});
  final List<PlayerStats> players;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class PlayerStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<StatsPage> loadPage({
    DocumentSnapshot<Map<String, dynamic>>? after,
    int pageSize = 50,
  }) async {
    if (pageSize < 1 || pageSize > 100) {
      throw RangeError.range(pageSize, 1, 100);
    }
    final uid = _uid;
    if (uid == null) return const StatsPage([], hasMore: false);
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(uid)
        .collection('stats')
        .orderBy(FieldPath.documentId);
    if (after != null) query = query.startAfterDocument(after);
    final snapshot = await query.limit(pageSize + 1).get();
    final page = snapshot.docs.take(pageSize).toList();
    return StatsPage(
      page
          .where((d) => d.id != 'career')
          .map(
            (d) => PlayerStats.fromJson({
              ...d.data(),
              'name': d.data()['name'] ?? d.id,
            }),
          )
          .toList(),
      cursor: page.lastOrNull,
      hasMore: snapshot.docs.length > pageSize,
    );
  }

  Future<void> clearStats() async {
    final uid = _uid;
    if (uid == null) return;
    final collection = _firestore
        .collection('users')
        .doc(uid)
        .collection('stats');
    while (true) {
      final page = await collection.limit(400).get();
      if (page.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}

final playerStatsRepoProvider = Provider<PlayerStatsRepository>((ref) {
  return PlayerStatsRepository();
});
