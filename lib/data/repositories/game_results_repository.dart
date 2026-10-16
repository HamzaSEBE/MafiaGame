import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/repositories/history_repository.dart';
import 'package:mafia_nightfall/data/repositories/player_stats_repository.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/data/repositories/result_receipt.dart';
import 'package:game_core/game_core.dart' show resultStats;
export 'package:game_core/game_core.dart' show resultStats;

/// A single commit records history and counters. An opaque receipt keeps
/// retries from restoring deleted records or counting aggregate stats twice.
class GameResultsRepository {
  GameResultsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore,
      _auth = auth;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  Future<void> save(
    GameRecord record,
    GameState state, {
    bool serverOwned = false,
  }) async {
    final uid = (_auth ?? FirebaseAuth.instance).currentUser?.uid;
    if (uid == null) throw StateError('Sign in to save game results.');
    if (state.winner == null || record.id != state.id) {
      throw StateError('Only completed games can be recorded.');
    }
    final db = _firestore ?? FirebaseFirestore.instance;
    final user = db.collection('users').doc(uid);
    if (serverOwned) {
      await user
          .collection('games')
          .doc(record.id)
          .snapshots()
          .firstWhere((d) => d.exists)
          .timeout(const Duration(seconds: 20));
      return;
    }
    final marker = user.collection('gameResults').doc(record.id);
    final v2Marker = user.collection('gameResultsV2').doc(record.id);
    final receipt = user
        .collection('resultReceipts')
        .doc(resultReceiptId(uid, record.id));
    final stats = resultStats(state);
    await db.runTransaction((transaction) async {
      if ((await transaction.get(receipt)).exists) return;
      if ((await transaction.get(marker)).exists ||
          (await transaction.get(v2Marker)).exists) {
        return;
      }
      transaction.set(
        user.collection('games').doc(record.id),
        GameSummary.fromRecord(record).toJson(),
      );
      transaction.set(
        user.collection('gameDetails').doc(record.id),
        record.toJson(),
      );
      for (final entry in stats.entries) {
        transaction.set(
          user.collection('stats').doc(playerStatsDocumentId(entry.key)),
          {
            'name': entry.key,
            for (final counter in entry.value.entries)
              counter.key: FieldValue.increment(counter.value),
          },
          SetOptions(merge: true),
        );
      }
      transaction.set(user.collection('stats').doc('career'), {
        'gamesPlayed': FieldValue.increment(1),
        if (state.winner?.name == 'mafia') 'mafiaWins': FieldValue.increment(1),
        if (state.winner?.name == 'citizens')
          'citizenWins': FieldValue.increment(1),
      }, SetOptions(merge: true));
      transaction.set(receipt, {'processed': true});
    });
  }
}

final gameResultsRepositoryProvider = Provider(
  (ref) => GameResultsRepository(),
);
