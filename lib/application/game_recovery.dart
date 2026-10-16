import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/data/repositories/checkpoints/local_checkpoint_repository.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';

class RecoverableGame {
  const RecoverableGame(this.state, {this.sessionId});
  final GameState state;
  final String? sessionId;
}

final checkpointErrorProvider = StateProvider<Object?>((ref) => null);
final gameRecoveryProvider = FutureProvider.autoDispose<RecoverableGame?>((
  ref,
) async {
  final uid = ref.watch(accountIdProvider);
  if (uid == null) return null;
  final checkpoints = ref.watch(localCheckpointRepositoryProvider);
  final local = await checkpoints.load(uid);
  final db = FirebaseFirestore.instance;
  final active = await db
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('activeSession')
      .get();
  final sessionId = active.data()?['sessionId'];
  if (sessionId is String && !await checkpoints.wasEnded(uid, sessionId)) {
    final service = ref.watch(interactiveServiceProvider);
    service.useProtocol(
      sessionId,
      active.data()?['protocolVersion'] as int? ?? 1,
    );
    final restored = await service.restoreCheckpoint(
      sessionId,
      claimHost: false,
    );
    if (restored != null) {
      return RecoverableGame(restored, sessionId: sessionId);
    }
    // Never resume an ended interactive game as an offline local game.
    if (local?.id == sessionId) return null;
  }
  return local == null ? null : RecoverableGame(local);
});
