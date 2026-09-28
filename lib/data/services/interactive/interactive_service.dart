import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
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

    await _firestore.collection('sessions').doc(sessionId).set(session.toJson());

    // Create seats
    final batch = _firestore.batch();
    for (var player in initialState.players) {
      final seat = InteractiveSeat(
        id: player.id,
        playerName: player.name,
        isAlive: player.isAlive,
        status: SeatStatus.unlinked,
      );
      final ref = _firestore.collection('sessions').doc(sessionId).collection('seats').doc(player.id);
      batch.set(ref, seat.toJson());
    }
    await batch.commit();

    return sessionId;
  }

  Stream<InteractiveSession?> streamSession(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InteractiveSession.fromJson(doc.data()!);
    });
  }

  Stream<List<InteractiveSeat>> streamSeats(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).collection('seats').snapshots().map((snap) {
      return snap.docs.map((d) => InteractiveSeat.fromJson(d.data())).toList();
    });
  }

  Stream<List<JoinRequest>> streamJoinRequests(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).collection('joinRequests').snapshots().map((snap) {
      return snap.docs.map((d) => JoinRequest.fromJson(d.data())).toList();
    });
  }

  Future<void> approveJoinRequest(String sessionId, String seatId, String playerUid) async {
    final batch = _firestore.batch();
    
    // Update seat
    final seatRef = _firestore.collection('sessions').doc(sessionId).collection('seats').doc(seatId);
    batch.update(seatRef, {
      'status': SeatStatus.linked.name,
      'linkedUid': playerUid,
    });

    // Delete request
    final reqRef = _firestore.collection('sessions').doc(sessionId).collection('joinRequests').doc(playerUid);
    batch.delete(reqRef);

    await batch.commit();
  }

  Future<void> rejectJoinRequest(String sessionId, String playerUid) async {
    await _firestore.collection('sessions').doc(sessionId).collection('joinRequests').doc(playerUid).delete();
  }

  Future<void> syncGameState(String sessionId, GameState state, Map<String, String>? requiredActions, Map<String, List<String>>? availableTargets) async {
    final batch = _firestore.batch();

    // Update public session state
    final sessionRef = _firestore.collection('sessions').doc(sessionId);
    batch.update(sessionRef, {
      'status': SessionStatus.active.name,
      'phase': state.phase.name,
      'round': state.round,
      'winner': state.winner?.name,
    });

    // Update private seats
    for (var player in state.players) {
      final seatRef = _firestore.collection('sessions').doc(sessionId).collection('seats').doc(player.id);
      final updateData = <String, dynamic>{
        'isAlive': player.isAlive,
        'role': player.role.name,
        'requiredActionType': requiredActions?[player.id],
        'availableTargets': availableTargets?[player.id],
        'hasSubmittedAction': false,
      };
      batch.update(seatRef, updateData);
    }

    await batch.commit();
  }

  Stream<List<ActionRequest>> streamActionRequests(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).collection('actionRequests').snapshots().map((snap) {
      return snap.docs.map((d) => ActionRequest.fromJson(d.data())).toList();
    });
  }

  Future<void> clearActionRequest(String sessionId, String requestId) async {
    await _firestore.collection('sessions').doc(sessionId).collection('actionRequests').doc(requestId).delete();
  }

  // ==========================================
  // PLAYER METHODS
  // ==========================================

  Future<void> requestSeat(String sessionId, String seatId, String displayName) async {
    await signInAnonymouslyIfNeeded();
    final playerUid = uid!;

    final req = JoinRequest(
      uid: playerUid,
      seatId: seatId,
      displayName: displayName,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('sessions').doc(sessionId).collection('joinRequests').doc(playerUid).set(req.toJson());
  }

  Stream<InteractiveSeat?> streamMySeat(String sessionId, String seatId) {
    return _firestore.collection('sessions').doc(sessionId).collection('seats').doc(seatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InteractiveSeat.fromJson(doc.data()!);
    });
  }

  Future<void> submitAction(String sessionId, String seatId, String actionType, String targetId) async {
    await signInAnonymouslyIfNeeded();
    final playerUid = uid!;
    final reqId = const Uuid().v4();

    final action = ActionRequest(
      id: reqId,
      uid: playerUid,
      actionType: actionType,
      targetId: targetId,
      timestamp: DateTime.now(),
    );

    final batch = _firestore.batch();
    
    // Write action
    final actionRef = _firestore.collection('sessions').doc(sessionId).collection('actionRequests').doc(reqId);
    batch.set(actionRef, action.toJson());

    // Mark seat as submitted
    final seatRef = _firestore.collection('sessions').doc(sessionId).collection('seats').doc(seatId);
    batch.update(seatRef, {'hasSubmittedAction': true});

    await batch.commit();
  }
}
