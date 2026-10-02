import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:uuid/uuid.dart';

final interactiveServiceProvider = Provider((ref) => InteractiveService());

class InteractiveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<void> signInAnonymouslyIfNeeded() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // ==========================================
  // JUDGE METHODS
  // ==========================================

  Future<String> createSession(GameState initialState) async {
    await signInAnonymouslyIfNeeded();
    final hostUid = uid!;
    final sessionId = initialState.id;

    final session = InteractiveSession(
      id: sessionId,
      hostUid: hostUid,
      status: SessionStatus.waiting,
      phase: initialState.phase,
      round: initialState.round,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .set(session.toJson());

    // Create seats and secrets
    final batch = _firestore.batch();
    for (var player in initialState.players) {
      final seat = InteractiveSeat(
        id: player.id,
        playerName: player.name,
        isAlive: player.isAlive,
        status: SeatStatus.unlinked,
      );
      final ref = _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('seats')
          .doc(player.id);
      batch.set(ref, seat.toJson());

      final secret = InteractiveSecret(
        id: player.id,
      );
      final secretRef = _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('secrets')
          .doc(player.id);
      batch.set(secretRef, secret.toJson());
    }
    await batch.commit();

    return sessionId;
  }

  Stream<InteractiveSession?> streamSession(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return InteractiveSession.fromJson(doc.data()!);
    });
  }

  Future<InteractiveSession?> getSession(String sessionId) async {
    final doc = await _firestore.collection('sessions').doc(sessionId).get();
    if (!doc.exists) return null;
    return InteractiveSession.fromJson(doc.data()!);
  }

  Stream<List<InteractiveSeat>> streamSeats(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('seats')
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => InteractiveSeat.fromJson(d.data())).toList();
    });
  }

  Stream<List<JoinRequest>> streamJoinRequests(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('joinRequests')
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => JoinRequest.fromJson(d.data())).toList();
    });
  }

  /// A participant can read only their own request document. Do not query the
  /// whole joinRequests collection from the web client: Firestore rules deny it.
  Stream<JoinRequest?> streamMyJoinRequest(String sessionId, String playerUid) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('joinRequests')
        .doc(playerUid)
        .snapshots()
        .map((doc) => doc.exists ? JoinRequest.fromJson(doc.data()!) : null);
  }

  Future<void> approveJoinRequest(
      String sessionId, String seatId, String playerUid) async {
    final batch = _firestore.batch();

    // Update seat
    final seatRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('seats')
        .doc(seatId);
    batch.update(seatRef, {
      'status': SeatStatus.linked.name,
      'linkedUid': playerUid,
    });

    // Delete request
    final reqRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('joinRequests')
        .doc(playerUid);
    batch.delete(reqRef);

    await batch.commit();
  }

  Future<void> rejectJoinRequest(String sessionId, String playerUid) async {
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('joinRequests')
        .doc(playerUid)
        .delete();
  }

  Future<void> syncGameState(
      String sessionId,
      GameState state,
      Map<String, String>? requiredActions,
      Map<String, List<String>>? availableTargets,
      {Map<String, List<PlayerActionPrompt>>? actionPrompts,
      Map<String, String>? privateResults,
      bool clearPrivateResults = false}) async {
    final batch = _firestore.batch();

    // Update public session state
    final sessionRef = _firestore.collection('sessions').doc(sessionId);
    final currentSession = await sessionRef.get();
    if (!currentSession.exists) {
      throw StateError('لا يمكن تحديث لعبة غير موجودة.');
    }
    final actionRevision =
        ((currentSession.data()?['actionRevision'] as num?)?.toInt() ?? 0) + 1;
    final hasActionPrompts = actionPrompts != null
        ? actionPrompts.values.any((prompts) => prompts.isNotEmpty)
        : requiredActions?.isNotEmpty ?? false;
    String? globalAnnouncement;
    if (state.eventHistory.isNotEmpty && state.eventHistory.last.type == EventType.citizenSheikhReveal) {
      final sheikhName = state.getPlayerById(state.eventHistory.last.actorId ?? '')?.name ?? 'شيخ المواطنين';
      globalAnnouncement = 'إفصاح شيخ المواطنين! اللاعب $sheikhName كشف عن نفسه! أصبح صوته الآن بـ 3 أصوات.';
    }

    batch.update(sessionRef, {
      'status': (state.phase == Phase.winCheck
              ? SessionStatus.finished
              : SessionStatus.active)
          .name,
      'phase': state.phase.name,
      'round': state.round,
      'actionRevision': actionRevision,
      'actionsPhase': hasActionPrompts ? state.phase.name : null,
      'actionsRound': hasActionPrompts ? state.round : null,
      'winner': state.winner?.name,
      if (globalAnnouncement != null) 'globalAnnouncement': globalAnnouncement,
    });

    // Update public seats and private secrets
    for (var player in state.players) {
      final seatRef = _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('seats')
          .doc(player.id);
      batch.update(seatRef, {
        'isAlive': player.isAlive,
        'isCitizenSheikhRevealed': player.isCitizenSheikhRevealed,
      });

      final secretRef = _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('secrets')
          .doc(player.id);
      final prompts = actionPrompts?[player.id] ??
          (requiredActions?[player.id] == null
              ? const <PlayerActionPrompt>[]
              : <PlayerActionPrompt>[
                  PlayerActionPrompt(
                    type: requiredActions![player.id]!,
                    availableTargets: availableTargets?[player.id] ?? const [],
                  ),
                ]);
      final secretData = <String, dynamic>{
        'role': player.role.name,
        'requiredActions': prompts.map((action) => action.toJson()).toList(),
        'requiredActionType': prompts.isEmpty ? null : prompts.first.type,
        'availableTargets':
            prompts.isEmpty ? null : prompts.first.availableTargets,
        'hasSubmittedAction': false,
        'isSniper': player.hasSniper,
        if (player.role.team == Team.mafia)
          'mafiaTeammates': state.players
              .where((p) => p.role.team == Team.mafia && p.id != player.id)
              .map((p) => p.name)
              .toList(),
      };
      if (clearPrivateResults) {
        secretData['privateResult'] = null;
      }
      if (privateResults?.containsKey(player.id) == true) {
        secretData['privateResult'] = privateResults![player.id];
      }
      batch.update(secretRef, secretData);
    }

    await batch.commit();
  }

  /// Publishes an investigation result to the investigating seat as soon as
  /// its action arrives. The transaction prevents a late result from an older
  /// night from overwriting the next phase's private state.
  Future<bool> publishInvestigationResult({
    required String sessionId,
    required String seatId,
    required int expectedRevision,
    required int expectedRound,
    required String result,
  }) {
    final sessionRef = _firestore.collection('sessions').doc(sessionId);
    final secretRef = sessionRef.collection('secrets').doc(seatId);

    return _firestore.runTransaction<bool>((transaction) async {
      final sessionSnapshot = await transaction.get(sessionRef);
      final sessionData = sessionSnapshot.data();
      if (sessionData == null ||
          sessionData['status'] != SessionStatus.active.name ||
          sessionData['phase'] != Phase.night.name ||
          sessionData['actionsPhase'] != Phase.night.name ||
          (sessionData['actionsRound'] as num?)?.toInt() != expectedRound ||
          (sessionData['round'] as num?)?.toInt() != expectedRound ||
          (sessionData['actionRevision'] as num?)?.toInt() !=
              expectedRevision) {
        return false;
      }

      transaction.update(secretRef, {'privateResult': result});
      return true;
    });
  }

  /// Closes the session so every connected player leaves the live game view.
  Future<void> endSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': SessionStatus.finished.name,
    });
  }

  Stream<List<ActionRequest>> streamActionRequests(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('actionRequests')
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => ActionRequest.fromJson(d.data())).toList();
    });
  }

  Stream<List<ActionRequest>> streamMyActionRequests(
      String sessionId, String playerUid) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('actionRequests')
        .where('uid', isEqualTo: playerUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActionRequest.fromJson(doc.data()))
            .toList());
  }

  Future<void> clearActionRequests(String sessionId) async {
    final requests = await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('actionRequests')
        .get();
    if (requests.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final request in requests.docs) {
      batch.delete(request.reference);
    }
    await batch.commit();
  }

  Future<void> clearActionRequest(String sessionId, String requestId) async {
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('actionRequests')
        .doc(requestId)
        .delete();
  }

  // ==========================================
  // PLAYER METHODS
  // ==========================================

  Future<void> requestSeat(
      String sessionId, String seatId, String displayName) async {
    await signInAnonymouslyIfNeeded();
    final playerUid = uid!;

    final req = JoinRequest(
      uid: playerUid,
      seatId: seatId,
      displayName: displayName,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('joinRequests')
        .doc(playerUid)
        .set(req.toJson());
  }

  Stream<InteractiveSeat?> streamMySeat(String sessionId, String seatId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('seats')
        .doc(seatId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return InteractiveSeat.fromJson(doc.data()!);
    });
  }

  Stream<InteractiveSecret?> streamMySecret(String sessionId, String seatId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('secrets')
        .doc(seatId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return InteractiveSecret.fromJson(doc.data()!);
    });
  }

  Future<void> submitAction(String sessionId, String seatId, String actionType,
      String targetId) async {
    await signInAnonymouslyIfNeeded();
    final playerUid = uid!;
    final reqId = const Uuid().v4();
    final session =
        await _firestore.collection('sessions').doc(sessionId).get();
    final revision = (session.data()?['actionRevision'] as num?)?.toInt() ?? 0;

    final action = ActionRequest(
      id: reqId,
      uid: playerUid,
      actionType: actionType,
      targetId: targetId,
      revision: revision,
      timestamp: DateTime.now(),
    );

    final batch = _firestore.batch();

    // Write action
    final actionRef = _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('actionRequests')
        .doc(reqId);
    batch.set(actionRef, action.toJson());

    // We no longer update the seat document from the client to prevent security rule violations!
    // Instead, the judge will monitor actionRequests and consider the action submitted.
    // Or we can allow the client to update ONLY `hasSubmittedAction` in `secrets`.
    // Wait, the client doesn't need to write `hasSubmittedAction` to Firestore,
    // the host listens to actionRequests and processes them!

    await batch.commit();
  }
}
