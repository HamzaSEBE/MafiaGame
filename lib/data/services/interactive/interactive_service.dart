import 'dart:convert';
import 'package:game_core/game_core.dart' show GameMachine;
import 'package:mafia_nightfall/application/theme_service.dart';
import 'dart:async';
import 'package:mafia_nightfall/core/config/app_environment.dart';
import 'package:mafia_nightfall/data/services/game_api/game_api_client.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';

final interactiveServiceProvider = Provider((ref) {
  final service = InteractiveService(
    preferredThemeId: () => ref.read(selectedThemeProvider),
    onAuthoritativeState: (state) =>
        ref.read(gameOrchestratorProvider.notifier).restoreCheckpoint(state),
  );
  ref.onDispose(service.dispose);
  return service;
});

class InteractiveService {
  InteractiveService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.onAuthoritativeState,
    this.preferredThemeId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final void Function(GameState)? onAuthoritativeState;
  final String Function()? preferredThemeId;
  late final GameApiClient _api = GameApiClient(_auth);
  final Map<String, Map<String, dynamic>> _serverRooms = {};
  final Map<String, int> _protocols = {};
  Timer? _heartbeat;
  bool _disposed = false;
  void dispose() {
    _disposed = true;
    _heartbeat?.cancel();
    _api.close();
  }

  void useProtocol(String id, int version) {
    _protocols[id] = version;
  }

  int protocolFor(String id) =>
      _protocols[id] ?? (AppEnvironment.serverGames ? 2 : 1);
  bool _v2(String id) => protocolFor(id) == 2;
  DocumentReference<Map<String, dynamic>> _sessionRef(String id) =>
      _firestore.collection(_v2(id) ? 'sessionsV2' : 'sessions').doc(id);
  Map<String, dynamic> _hostContract(String id) {
    final room = _serverRooms[id];
    if (room == null) throw StateError('أعد فتح الجلسة لاستعادة صلاحية الحكم.');
    return {
      'hostInstanceId': _api.hostInstanceId,
      'hostEpoch': room['hostEpoch'],
      'expectedVersion': room['stateVersion'],
    };
  }

  void _rememberRoom(String id, Map<String, dynamic> room) {
    _serverRooms[id] = room;
    _heartbeat ??= Timer.periodic(const Duration(seconds: 45), (_) async {
      if (_disposed) return;
      for (final entry in _serverRooms.entries.toList()) {
        if (entry.value['status'] == 'finished') continue;
        try {
          final fresh = await _api.request(entry.key, 'claim', {
            'hostInstanceId': _api.hostInstanceId,
          });
          if (!_disposed) _serverRooms[entry.key] = fresh;
        } catch (_) {
          /* The next explicit command reports a lost lease. */
        }
      }
    });
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Future<void>? _signIn;
  final Map<String, int> _stateVersions = {};
  final Map<String, Future<void>> _hostWrites = {};
  final Map<(String, String, String), Future<void>> _approvals = {};
  final Map<String, Map<String, (bool, bool, bool)>> _publishedSeats = {};

  // A session is a party-sized room; large concurrency is spread across rooms.
  // This bounds the largest atomic write (session + seats + secrets).
  static const maxSessionPlayers = 200;

  Future<void> _serializeHostWrite(
    String sessionId,
    Future<void> Function() operation,
  ) {
    final previous = _hostWrites[sessionId] ?? Future<void>.value();
    final next = previous.then(
      (_) => operation(),
      onError: (Object _, StackTrace __) => operation(),
    );
    _hostWrites[sessionId] = next;
    return next.whenComplete(() {
      if (identical(_hostWrites[sessionId], next)) {
        _hostWrites.remove(sessionId);
      }
    });
  }

  Map<String, dynamic> _readData(Map<String, dynamic> data) => {
    ...data,
    for (final key in ['timestamp', 'createdAt'])
      if (data[key] is Timestamp)
        key: (data[key] as Timestamp).toDate().toIso8601String(),
  };

  void _validateRoom(GameState state) {
    if (state.players.isEmpty || state.players.length > maxSessionPlayers) {
      throw StateError(
        'يجب أن تضم الجلسة من لاعب إلى $maxSessionPlayers لاعب.',
      );
    }
    if (state.players.map((player) => player.id).toSet().length !=
        state.players.length) {
      throw StateError('لا يمكن تكرار معرّف اللاعب داخل الجلسة.');
    }
  }

  String? get uid => _auth.currentUser?.uid;

  Future<void> signInAnonymouslyIfNeeded() async {
    if (_auth.currentUser != null) return;
    final pending = _signIn ??= _auth.signInAnonymously().then((_) {});
    try {
      await pending;
    } finally {
      if (identical(_signIn, pending)) _signIn = null;
    }
  }

  // ==========================================
  // JUDGE METHODS
  // ==========================================

  Future<String> createSession(GameState initialState) async {
    _validateRoom(initialState);
    await signInAnonymouslyIfNeeded();
    final hostUid = uid!;
    final sessionId = initialState.id;
    if (_v2(sessionId)) {
      final room = await _api.request(sessionId, 'create', {
        'hostInstanceId': _api.hostInstanceId,
        'state': initialState.toJson(),
        'themeId': preferredThemeId?.call() ?? 'dark_blood',
      });
      _rememberRoom(sessionId, room);
      final checkpoint = await _sessionRef(sessionId)
          .collection('hostState')
          .doc('current')
          .get(const GetOptions(source: Source.server));
      if (!_disposed && room['hostUid'] == uid) {
        onAuthoritativeState?.call(
          GameState.fromJson(
            Map<String, dynamic>.from(checkpoint.data()!['state'] as Map),
          ),
        );
      }
      return sessionId;
    }
    final sessionRef = _sessionRef(sessionId);
    final session = InteractiveSession(
      id: sessionId,
      hostUid: hostUid,
      status: SessionStatus.waiting,
      phase: initialState.phase,
      round: initialState.round,
      createdAt: DateTime.now(),
    );

    var created = false;
    await _serializeHostWrite(sessionId, () async {
      await _firestore.runTransaction<void>((transaction) async {
        created = false;
        final existing = await transaction.get(sessionRef);
        if (existing.exists) {
          // A retry must not wipe linked players, secrets, or a running game.
          if (existing.data()?['hostUid'] == hostUid) return;
          throw StateError('معرّف الجلسة مستخدم بالفعل.');
        }
        created = true;
        transaction.set(sessionRef, {
          ...session.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24)),
          ),
        });
        transaction.set(sessionRef.collection('hostState').doc('current'), {
          'schemaVersion': 1,
          'state': initialState.toJson(),
        });
        transaction.set(
          _firestore
              .collection('users')
              .doc(hostUid)
              .collection('settings')
              .doc('activeSession'),
          {'sessionId': sessionId},
        );
        for (final player in initialState.players) {
          transaction.set(
            sessionRef.collection('seats').doc(player.id),
            InteractiveSeat(
              id: player.id,
              playerName: player.name,
              isAlive: player.isAlive,
              status: SeatStatus.unlinked,
            ).toJson(),
          );
          transaction.set(
            sessionRef.collection('secrets').doc(player.id),
            InteractiveSecret(id: player.id).toJson(),
          );
        }
      });
      // Do not seed the diff cache here: this may have been an existing room.
    });
    if (created) {
      _stateVersions[sessionId] = 0;
    } else {
      await getSession(sessionId);
    }
    return sessionId;
  }

  Stream<InteractiveSession?> streamSession(String sessionId) {
    return _sessionRef(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InteractiveSession.fromJson(_readData(doc.data()!));
    });
  }

  Future<InteractiveSession?> getSession(String sessionId) async {
    final doc = await _sessionRef(sessionId).get();
    if (!doc.exists) return null;
    final session = InteractiveSession.fromJson(_readData(doc.data()!));
    _stateVersions.putIfAbsent(sessionId, () => session.stateVersion);
    return session;
  }

  Future<GameState?> reconcileHostState(String sessionId) async {
    final room = await _sessionRef(
      sessionId,
    ).get(const GetOptions(source: Source.server));
    if (room.data()?['hostUid'] != uid) {
      throw StateError('لا تملك صلاحية استرجاع الجلسة.');
    }
    _stateVersions[sessionId] =
        (room.data()?['stateVersion'] as num?)?.toInt() ?? 0;
    if (room.data()?['status'] == 'finished') {
      final checkpoint = await _sessionRef(sessionId)
          .collection('hostState')
          .doc('current')
          .get(const GetOptions(source: Source.server));
      if (checkpoint.data()?['schemaVersion'] != 1) return null;
      return GameState.fromJson(
        Map<String, dynamic>.from(checkpoint.data()!['state'] as Map),
      );
    }
    return restoreCheckpoint(sessionId);
  }

  Future<GameState?> restoreCheckpoint(
    String sessionId, {
    bool claimHost = true,
    bool takeOver = false,
  }) async {
    if (_v2(sessionId) && claimHost) {
      final room = await _api.request(sessionId, 'claim', {
        'hostInstanceId': _api.hostInstanceId,
        if (takeOver) 'takeOver': true,
      });
      _rememberRoom(sessionId, room);
      final pending = room['pendingTransition'];
      if (pending is String) {
        final intent = await _sessionRef(
          sessionId,
        ).collection('transitions').doc(pending).get();
        final result = await _api.request(sessionId, 'transition', {
          ..._hostContract(sessionId),
          'commandId': pending,
          'desiredPhase': intent.data()?['desiredPhase'],
          'hasPrompts': intent.data()?['hasPrompts'],
        });
        _rememberRoom(
          sessionId,
          Map<String, dynamic>.from(result['room'] as Map),
        );
      }
    }
    final session = await getSession(sessionId);
    if (session == null ||
        session.hostUid != uid ||
        session.status == SessionStatus.finished) {
      return null;
    }
    final checkpoint = await _sessionRef(sessionId)
        .collection('hostState')
        .doc('current')
        .get(const GetOptions(source: Source.server));
    if (checkpoint.data()?['schemaVersion'] != 1) return null;
    _stateVersions[sessionId] = session.stateVersion;
    return GameState.fromJson(
      Map<String, dynamic>.from(checkpoint.data()!['state'] as Map),
    );
  }

  /// Closing the gate first provides an immutable set even after a lost reply.
  /// Retrying the same revision reads the same retained action documents.
  Future<List<ActionRequest>> freezeActions(
    String sessionId,
    int expectedRevision,
  ) async {
    if (_v2(sessionId)) {
      final result = await _api.request(sessionId, 'freeze', {
        ..._hostContract(sessionId),
        'expectedRevision': expectedRevision,
      });
      _rememberRoom(
        sessionId,
        Map<String, dynamic>.from(result['room'] as Map),
      );
      return (result['actions'] as List)
          .map(
            (a) => ActionRequest.fromJson(Map<String, dynamic>.from(a as Map)),
          )
          .toList();
    }
    await _serializeHostWrite(sessionId, () async {
      final roomRef = _sessionRef(sessionId);
      final expectedVersion = _stateVersions[sessionId];
      int committedVersion = 0;
      await _firestore.runTransaction<void>((tx) async {
        final room = (await tx.get(roomRef)).data();
        if (room == null ||
            room['hostUid'] != uid ||
            room['status'] != 'active' ||
            room['actionRevision'] != expectedRevision) {
          throw StateError('نافذة الحركات تغيّرت. أعد فتح الجلسة.');
        }
        final version = (room['stateVersion'] as num?)?.toInt() ?? 0;
        if (expectedVersion == null || expectedVersion != version) {
          throw StateError('تم تعديل الجلسة من جهاز آخر. أعد فتحها.');
        }
        committedVersion = room['actionsOpen'] == false ? version : version + 1;
        if (room['actionsOpen'] == false) return;
        tx.update(roomRef, {'actionsOpen': false, 'stateVersion': version + 1});
      });
      _stateVersions[sessionId] = committedVersion;
    });
    final snapshot = await _sessionRef(sessionId)
        .collection('actionRequests')
        .where('revision', isEqualTo: expectedRevision)
        .limit(maxSessionPlayers * 9 + 1)
        .get(const GetOptions(source: Source.server));
    if (snapshot.docs.length > maxSessionPlayers * 9) {
      throw StateError('عدد الحركات تجاوز حد الجلسة.');
    }
    return snapshot.docs
        .map((d) => ActionRequest.fromJson(_readData(d.data())))
        .toList();
  }

  Stream<List<InteractiveSeat>> streamSeats(String sessionId) {
    final host = _serverRooms.containsKey(sessionId);
    final name = _v2(sessionId) && !host ? 'roster' : 'seats';
    return _sessionRef(sessionId).collection(name).snapshots().asyncMap((
      snap,
    ) async {
      String? ownSeat;
      if (_v2(sessionId) && !host && uid != null) {
        ownSeat =
            (await _sessionRef(
                  sessionId,
                ).collection('members').doc(uid).get()).data()?['seatId']
                as String?;
      }
      return snap.docs
          .map(
            (d) => InteractiveSeat.fromJson({
              ...d.data(),
              if (d.id == ownSeat) 'linkedUid': uid,
            }),
          )
          .toList();
    });
  }

  Stream<List<JoinRequest>> streamJoinRequests(String sessionId) {
    return _sessionRef(sessionId).collection('joinRequests').snapshots().map((
      snap,
    ) {
      return snap.docs
          .map((d) => JoinRequest.fromJson(_readData(d.data())))
          .toList();
    });
  }

  /// A participant can read only their own request document. Do not query the
  /// whole joinRequests collection from the web client: Firestore rules deny it.
  Stream<JoinRequest?> streamMyJoinRequest(String sessionId, String playerUid) {
    return _sessionRef(sessionId)
        .collection('joinRequests')
        .doc(playerUid)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? JoinRequest.fromJson(_readData(doc.data()!)) : null,
        );
  }

  /// Approval's atomic membership write is the earliest authoritative signal
  /// for a guest. It avoids waiting for a full roster query to refresh.
  Stream<String?> streamMyMembership(String sessionId, String playerUid) =>
      _sessionRef(sessionId)
          .collection('members')
          .doc(playerUid)
          .snapshots()
          .map((doc) => doc.exists ? (doc.data()?['seatId'] as String?) : null);

  Future<void> approveJoinRequest(
    String sessionId,
    String seatId,
    String playerUid,
  ) {
    final key = (sessionId, seatId, playerUid);
    final pending = _approvals[key];
    if (pending != null) return pending;
    final operation = _approveJoinRequest(sessionId, seatId, playerUid);
    _approvals[key] = operation;
    return operation.whenComplete(() {
      if (identical(_approvals[key], operation)) _approvals.remove(key);
    });
  }

  Future<void> _approveJoinRequest(
    String sessionId,
    String seatId,
    String playerUid,
  ) async {
    if (_v2(sessionId)) {
      await _api.request(sessionId, 'approve', {
        ..._hostContract(sessionId),
        'seatId': seatId,
        'playerUid': playerUid,
      });
      return;
    }
    final sessionRef = _sessionRef(sessionId);
    final seatRef = sessionRef.collection('seats').doc(seatId);
    final requestRef = sessionRef.collection('joinRequests').doc(playerUid);
    final memberRef = sessionRef.collection('members').doc(playerUid);

    await _firestore.runTransaction<void>((transaction) async {
      // Independent reads share one wait instead of four sequential waits.
      // All validation stays inside the transaction, including seat conflicts.
      final documents = await Future.wait([
        transaction.get(sessionRef),
        transaction.get(seatRef),
        transaction.get(requestRef),
        transaction.get(memberRef),
      ]);
      final session = documents[0],
          seat = documents[1],
          request = documents[2],
          member = documents[3];
      if (session.data()?['status'] == SessionStatus.finished.name ||
          !session.exists ||
          !seat.exists) {
        throw StateError('الجلسة أو المقعد لم يعد متاحًا.');
      }
      final linkedUid = seat.data()?['linkedUid'];
      if (linkedUid == playerUid && member.data()?['seatId'] == seatId) return;
      if (linkedUid != null || member.exists) {
        throw StateError('تم ربط هذا المقعد أو هذا اللاعب بالفعل.');
      }
      if (request.data()?['seatId'] != seatId) {
        throw StateError('تغيّر طلب اللاعب. أعد تحميل الطلبات.');
      }
      transaction.update(seatRef, {
        'status': SeatStatus.linked.name,
        'linkedUid': playerUid,
      });
      transaction.set(memberRef, {'uid': playerUid, 'seatId': seatId});
      transaction.delete(requestRef);
    });
  }

  Future<void> rejectJoinRequest(String sessionId, String playerUid) async {
    if (_v2(sessionId)) {
      await _api.request(sessionId, 'reject', {
        ..._hostContract(sessionId),
        'playerUid': playerUid,
      });
      return;
    }
    await _sessionRef(
      sessionId,
    ).collection('joinRequests').doc(playerUid).delete();
  }

  Future<void> syncGameState(
    String sessionId,
    GameState state,
    Map<String, String>? requiredActions,
    Map<String, List<String>>? availableTargets, {
    Map<String, List<PlayerActionPrompt>>? actionPrompts,
    Map<String, String>? privateResults,
    bool clearPrivateResults = false,
    bool moderatorRewind = false,
    bool isRematch = false,
  }) => _serializeHostWrite(sessionId, () async {
    _validateRoom(state);
    if (_v2(sessionId)) {
      if (moderatorRewind ||
          isRematch ||
          state.players.any((p) => p.isKicked)) {
        throw StateError('هذه الأدوات متاحة في غرف QR الحالية فقط.');
      }
      final hasPrompts =
          actionPrompts?.values.any((p) => p.isNotEmpty) ??
          requiredActions?.isNotEmpty ??
          false;
      final result = await _api.request(
        sessionId,
        'transition',
        {
          ..._hostContract(sessionId),
          'desiredPhase': state.phase.name,
          'hasPrompts': hasPrompts,
        },
        retryKey:
            'transition:$sessionId:${state.round}:${state.phase.name}:$hasPrompts',
      );
      _rememberRoom(
        sessionId,
        Map<String, dynamic>.from(result['room'] as Map),
      );
      if (!_disposed && (result['room'] as Map)['hostUid'] == uid) {
        onAuthoritativeState?.call(
          GameState.fromJson(Map<String, dynamic>.from(result['state'] as Map)),
        );
      }
      return;
    }
    if (utf8.encode(jsonEncode(state.toJson())).length > 700000) {
      throw StateError('حجم سجل اللعبة تجاوز الحد الآمن.');
    }
    if (!_stateVersions.containsKey(sessionId)) await getSession(sessionId);
    final expectedVersion = _stateVersions[sessionId];
    int committedVersion = 0;
    GameState? alreadyStarted;
    final changedSeats = <String, (bool, bool, bool)>{};
    await _firestore.runTransaction<void>((transaction) async {
      // Update public session state
      final sessionRef = _sessionRef(sessionId);
      final currentSession = await transaction.get(sessionRef);
      if (!currentSession.exists ||
          currentSession.data()?['closed'] == true ||
          (currentSession.data()?['status'] == SessionStatus.finished.name &&
              !isRematch)) {
        throw StateError('لا يمكن تحديث لعبة غير موجودة.');
      }
      final currentVersion =
          (currentSession.data()?['stateVersion'] as num?)?.toInt() ?? 0;
      if (isRematch &&
          currentSession.data()?['matchId'] == state.id &&
          currentSession.data()?['status'] == 'active') {
        final saved = await transaction.get(
          sessionRef.collection('hostState').doc('current'),
        );
        alreadyStarted = GameState.fromJson(
          Map<String, dynamic>.from(saved.data()!['state'] as Map),
        );
        committedVersion = currentVersion;
        return;
      }
      if (expectedVersion != currentVersion) {
        throw StateError('توجد حالة أحدث على الخادم. أعد فتح شاشة الحكم.');
      }
      committedVersion = currentVersion + 1;
      if (!moderatorRewind &&
          !isRematch &&
          state.round <
              ((currentSession.data()?['round'] as num?)?.toInt() ?? 1)) {
        throw StateError('توجد جولة أحدث على الخادم. أعد فتح شاشة الحكم.');
      }
      final checkpointRef = sessionRef.collection('hostState').doc('current');
      if (isRematch) {
        final saved = await transaction.get(checkpointRef);
        final previous = GameState.fromJson(
          Map<String, dynamic>.from(saved.data()!['state'] as Map),
        );
        final expectedIds = previous.players
            .where((p) => !p.isKicked)
            .map((p) => p.id)
            .toSet();
        if (previous.phase != Phase.winCheck ||
            state.id == previous.id ||
            state.phase != Phase.roleReveal ||
            state.round != 1 ||
            state.players.length != expectedIds.length ||
            !state.players.every(
              (p) => expectedIds.contains(p.id) && p.isAlive && !p.isKicked,
            ) ||
            jsonEncode(state.rules.toJson()) !=
                jsonEncode(previous.rules.toJson())) {
          throw StateError(
            'إعادة المباراة تحفظ نفس اللاعبين والقواعد وتتطلب أدواراً جديدة.',
          );
        }
      } else if (currentSession.data()?['matchId'] != null &&
          currentSession.data()?['matchId'] != state.id) {
        throw StateError('بدأت مباراة أخرى في هذه الغرفة. أعد فتح شاشة الحكم.');
      }
      final actionRevision =
          ((currentSession.data()?['actionRevision'] as num?)?.toInt() ?? 0) +
          1;
      final hasActionPrompts = actionPrompts != null
          ? actionPrompts.values.any((prompts) => prompts.isNotEmpty)
          : requiredActions?.isNotEmpty ?? false;
      String? globalAnnouncement;
      if (state.eventHistory.isNotEmpty &&
          state.eventHistory.last.type == EventType.citizenSheikhReveal) {
        final sheikhName =
            state.getPlayerById(state.eventHistory.last.actorId ?? '')?.name ??
            'شيخ المواطنين';
        globalAnnouncement =
            'إفصاح شيخ المواطنين! اللاعب $sheikhName كشف عن نفسه! أصبح صوته الآن بـ 3 أصوات.';
      }

      transaction.update(sessionRef, {
        'status':
            (state.phase == Phase.winCheck
                    ? SessionStatus.finished
                    : SessionStatus.active)
                .name,
        'phase': state.phase.name,
        'round': state.round,
        'matchId': state.id,
        'closed': false,
        'actionRevision': actionRevision,
        'stateVersion': committedVersion,
        'actionsOpen': state.phase != Phase.winCheck,
        'actionsPhase': hasActionPrompts ? state.phase.name : null,
        'actionsRound': hasActionPrompts ? state.round : null,
        'winner': state.winner?.name,
        'globalAnnouncement': globalAnnouncement,
      });

      transaction.set(sessionRef.collection('hostState').doc('current'), {
        'schemaVersion': 1,
        'state': state.toJson(),
      });
      // Update public seats and private secrets
      for (var player in state.players) {
        final seatRef = _sessionRef(
          sessionId,
        ).collection('seats').doc(player.id);
        final publicState = (
          player.isAlive,
          player.isCitizenSheikhRevealed,
          player.isKicked,
        );
        if (_publishedSeats[sessionId]?[player.id] != publicState) {
          transaction.update(seatRef, {
            'isAlive': player.isAlive,
            'isKicked': player.isKicked,
            'isCitizenSheikhRevealed': player.isCitizenSheikhRevealed,
          });
        }
        changedSeats[player.id] = publicState;

        final secretRef = _sessionRef(
          sessionId,
        ).collection('secrets').doc(player.id);
        final prompts = player.isKicked
            ? const <PlayerActionPrompt>[]
            : actionPrompts?[player.id] ??
                  (requiredActions?[player.id] == null
                      ? const <PlayerActionPrompt>[]
                      : <PlayerActionPrompt>[
                          PlayerActionPrompt(
                            type: requiredActions![player.id]!,
                            availableTargets:
                                availableTargets?[player.id] ?? const [],
                          ),
                        ]);
        final secretData = <String, dynamic>{
          'role': player.role.name,
          'promptRevision': actionRevision,
          'requiredActions': prompts.map((action) => action.toJson()).toList(),
          'allowedTargetsByAction': {
            for (final prompt in prompts) prompt.type: prompt.availableTargets,
          },
          'requiredActionType': prompts.isEmpty ? null : prompts.first.type,
          'availableTargets': prompts.isEmpty
              ? null
              : prompts.first.availableTargets,
          'hasSubmittedAction': false,
          'isSniper': player.hasSniper,
          'canReveal':
              state.rules.abilityRules.citizenSheikhReveal &&
              player.role == Role.citizensSheikh,
          'mafiaTeammates': player.role.team == Team.mafia
              ? state.players
                    .where(
                      (p) => p.role.team == Team.mafia && p.id != player.id,
                    )
                    .map((p) => p.name)
                    .toList()
              : <String>[],
        };
        if (clearPrivateResults ||
            moderatorRewind ||
            isRematch ||
            player.isKicked) {
          secretData['privateResult'] = null;
        }
        if (privateResults?.containsKey(player.id) == true) {
          secretData['privateResult'] = privateResults![player.id];
        }
        transaction.update(secretRef, secretData);
      }
    });
    _stateVersions[sessionId] = committedVersion;
    _publishedSeats[sessionId] = changedSeats;
    if (alreadyStarted != null && !_disposed) {
      onAuthoritativeState?.call(alreadyStarted!);
    }
  });

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
    if (_v2(sessionId)) return Future.value(true);
    final sessionRef = _sessionRef(sessionId);
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

  /// A reveal updates public information without replacing prompts or changing
  /// their revision, so ballots already submitted remain part of the vote.
  Future<bool> publishCitizenSheikhReveal({
    required String sessionId,
    required String seatId,
    required int expectedRevision,
    required String playerName,
  }) => _serializeReveal(sessionId, seatId, expectedRevision, playerName);

  Future<bool> _serializeReveal(
    String sessionId,
    String seatId,
    int expectedRevision,
    String playerName,
  ) async {
    if (_v2(sessionId)) {
      // V2 applies reveals immediately on the server, including the checkpoint.
      final room = await _api.request(sessionId, 'claim', {
        'hostInstanceId': _api.hostInstanceId,
      });
      _rememberRoom(sessionId, room);
      return true;
    }
    bool published = false;
    await _serializeHostWrite(sessionId, () async {
      final sessionRef = _sessionRef(sessionId);
      await _firestore.runTransaction<void>((transaction) async {
        final session = await transaction.get(sessionRef);
        final seatRef = sessionRef.collection('seats').doc(seatId);
        final seat = await transaction.get(seatRef);
        if (session.data()?['status'] != SessionStatus.active.name ||
            session.data()?['actionRevision'] != expectedRevision ||
            ![
              Phase.day.name,
              Phase.voting.name,
            ].contains(session.data()?['phase']) ||
            seat.data()?['isAlive'] != true) {
          return;
        }
        transaction.update(seatRef, {'isCitizenSheikhRevealed': true});
        transaction.update(sessionRef, {
          'globalAnnouncement':
              'إفصاح شيخ المواطنين! اللاعب $playerName كشف عن نفسه! أصبح صوته الآن بـ 3 أصوات.',
        });
        published = true;
      });
      // The next full sync should read this public update into its diff cache.
      _publishedSeats[sessionId]?.remove(seatId);
    });
    return published;
  }

  Future<void> setDiscussionClock(
    String sessionId,
    int seconds, {
    required bool paused,
  }) => _serializeHostWrite(sessionId, () async {
    if (_v2(sessionId)) {
      final result = await _api.request(sessionId, 'clock', {
        ..._hostContract(sessionId),
        'remainingSeconds': seconds,
        'paused': paused,
      });
      _rememberRoom(
        sessionId,
        Map<String, dynamic>.from(result['room'] as Map),
      );
      if (!_disposed && (result['room'] as Map)['hostUid'] == uid) {
        onAuthoritativeState?.call(
          GameState.fromJson(Map<String, dynamic>.from(result['state'] as Map)),
        );
      }
      return;
    }
    final ref = _sessionRef(sessionId);
    final expected = _stateVersions[sessionId];
    int committed = 0;
    await _firestore.runTransaction<void>((tx) async {
      final room = await tx.get(ref),
          checkpoint = await tx.get(ref.collection('hostState').doc('current'));
      final version = (room.data()?['stateVersion'] as num?)?.toInt() ?? 0;
      if (expected != version ||
          room.data()?['phase'] != 'day' ||
          !checkpoint.exists) {
        throw StateError('تغيرت حالة النقاش. أعد فتح الجلسة.');
      }
      final g = GameMachine(
        GameState.fromJson(
          Map<String, dynamic>.from(checkpoint.data()!['state'] as Map),
        ),
      );
      g.updateDiscussionClock(seconds, paused: paused);
      committed = version + 1;
      tx.update(ref, {'stateVersion': committed});
      tx.set(ref.collection('hostState').doc('current'), {
        'schemaVersion': 1,
        'state': g.state.toJson(),
      });
    });
    _stateVersions[sessionId] = committed;
  });

  /// Closes the session so every connected player leaves the live game view.
  Future<void> endSession(String sessionId) =>
      _serializeHostWrite(sessionId, () async {
        if (_v2(sessionId)) {
          await _api.request(sessionId, 'end', _hostContract(sessionId));
          _serverRooms.remove(sessionId);
          return;
        }
        final hostUid = _auth.currentUser?.uid;
        if (hostUid == null) throw StateError('سجّل الدخول لإنهاء الجلسة.');
        final activeRef = _firestore
            .collection('users')
            .doc(hostUid)
            .collection('settings')
            .doc('activeSession');
        await _firestore.runTransaction<void>((transaction) async {
          final active = await transaction.get(activeRef);
          transaction.update(_sessionRef(sessionId), {
            'status': SessionStatus.finished.name,
            'closed': true,
            'actionsOpen': false,
            'actionsPhase': null,
            'actionsRound': null,
          });
          if (active.data()?['sessionId'] == sessionId) {
            transaction.delete(activeRef);
          }
        });
        _publishedSeats.remove(sessionId);
      });

  Stream<List<ActionRequest>> streamActionRequests(String sessionId) {
    return _sessionRef(sessionId).collection('actionRequests').snapshots().map((
      snap,
    ) {
      return snap.docs
          .map((d) => ActionRequest.fromJson(_readData(d.data())))
          .toList();
    });
  }

  Stream<List<ActionRequest>> streamMyActionRequests(
    String sessionId,
    String playerUid,
  ) {
    return _sessionRef(sessionId)
        .collection('actionRequests')
        .where('uid', isEqualTo: playerUid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActionRequest.fromJson(_readData(doc.data())))
              .toList(),
        );
  }

  // ==========================================
  // PLAYER METHODS
  // ==========================================

  Future<void> requestSeat(
    String sessionId,
    String seatId,
    String displayName,
  ) async {
    await signInAnonymouslyIfNeeded();
    final playerUid = uid!;
    if (_v2(sessionId)) {
      await _api.request(sessionId, 'join', {
        'seatId': seatId,
        'displayName': displayName,
      });
      return;
    }

    final req = JoinRequest(
      uid: playerUid,
      seatId: seatId,
      displayName: displayName,
      timestamp: DateTime.now(),
    );

    await _sessionRef(sessionId).collection('joinRequests').doc(playerUid).set({
      ...req.toJson(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<InteractiveSeat?> streamMySeat(String sessionId, String seatId) {
    return _sessionRef(
      sessionId,
    ).collection('seats').doc(seatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InteractiveSeat.fromJson(doc.data()!);
    });
  }

  Stream<InteractiveSecret?> streamMySecret(String sessionId, String seatId) {
    return _sessionRef(
      sessionId,
    ).collection('secrets').doc(seatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InteractiveSecret.fromJson(doc.data()!);
    });
  }

  Future<void> submitAction(
    String sessionId,
    String seatId,
    String actionType,
    String targetId, {
    required int expectedRevision,
    int expectedActionVersion = 0,
  }) async {
    await signInAnonymouslyIfNeeded();
    final playerUid = uid!;
    if (_v2(sessionId)) {
      await _api.request(
        sessionId,
        'action',
        {
          'seatId': seatId,
          'actionType': actionType,
          'targetId': targetId,
          'expectedRevision': expectedRevision,
          'expectedActionVersion': expectedActionVersion,
        },
        retryKey:
            'action:$sessionId:$expectedRevision:$actionType:$targetId:$expectedActionVersion',
      );
      return;
    }
    final sessionRef = _sessionRef(sessionId);
    // Updating a vote never grows the collection. A night action is immutable
    // for one revision, including retries from another tab or a lost response.
    final requestId = '${playerUid}_$actionType';
    final actionRef = sessionRef.collection('actionRequests').doc(requestId);
    await _firestore.runTransaction<void>((transaction) async {
      final session = await transaction.get(sessionRef);
      final seat = await transaction.get(
        sessionRef.collection('seats').doc(seatId),
      );
      final secret = await transaction.get(
        sessionRef.collection('secrets').doc(seatId),
      );
      final previous = await transaction.get(actionRef);
      final data = session.data();
      if (data == null ||
          data['status'] != SessionStatus.active.name ||
          seat.data()?['linkedUid'] != playerUid ||
          seat.data()?['isKicked'] == true ||
          !secret.exists) {
        throw StateError('الجلسة أو المقعد لم يعد متاحًا.');
      }
      final revision = (data['actionRevision'] as num?)?.toInt() ?? 0;
      if (revision != expectedRevision ||
          data['actionsOpen'] == false ||
          secret.data()?['promptRevision'] != expectedRevision) {
        throw StateError('انتهت نافذة الحركة. اختر مجدداً في الجولة الحالية.');
      }
      final isReveal = actionType == 'citizenSheikhReveal';
      final prompts = InteractiveSecret.fromJson(
        secret.data()!,
      ).requiredActions;
      final seatData = seat.data()!;
      final secretData = secret.data()!;
      final canAct = isReveal
          ? seatData['isAlive'] == true &&
                seatData['isCitizenSheikhRevealed'] != true &&
                secretData['role'] == Role.citizensSheikh.name &&
                secretData['canReveal'] == true &&
                [Phase.day.name, Phase.voting.name].contains(data['phase']) &&
                targetId == seatId
          : data['actionsPhase'] == data['phase'] &&
                data['actionsRound'] == data['round'] &&
                (seat.data()?['isAlive'] == true ||
                    actionType == 'retaliation') &&
                prompts.any(
                  (prompt) =>
                      prompt.type == actionType &&
                      prompt.availableTargets.contains(targetId),
                );
      if (!canAct) throw StateError('هذه الحركة لم تعد متاحة.');
      if (previous.data()?['revision'] == revision && actionType != 'vote') {
        if (previous.data()?['targetId'] == targetId) return;
        throw StateError('تم إرسال هذه الحركة بالفعل.');
      }
      final action = ActionRequest(
        id: requestId,
        uid: playerUid,
        seatId: seatId,
        actionType: actionType,
        targetId: targetId,
        revision: revision,
        timestamp: DateTime.now(),
      );
      transaction.set(actionRef, {
        ...action.toJson(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
