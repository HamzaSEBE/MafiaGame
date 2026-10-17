import 'package:game_core/src/enums/phase.dart';
import 'package:game_core/src/enums/role.dart';

enum SessionStatus { waiting, active, finished }

enum SeatStatus { unlinked, requested, linked }

class InteractiveSession {
  final String id;
  final bool closed;
  final String hostUid;
  final SessionStatus status;
  final Phase phase;
  final int round;
  final int actionRevision;
  final int stateVersion;
  final bool actionsOpen;
  final Phase? actionsPhase;
  final int? actionsRound;
  final Team? winner;
  final DateTime createdAt;
  final String? globalAnnouncement;
  final String? sharedThemeId;
  final int? themeVersion;

  InteractiveSession({
    required this.id,
    this.closed = false,
    required this.hostUid,
    required this.status,
    required this.phase,
    required this.round,
    this.actionRevision = 0,
    this.stateVersion = 0,
    this.actionsOpen = true,
    this.actionsPhase,
    this.actionsRound,
    this.winner,
    required this.createdAt,
    this.globalAnnouncement,
    this.sharedThemeId,
    this.themeVersion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'closed': closed,
    'hostUid': hostUid,
    'status': status.name,
    'phase': phase.name,
    'round': round,
    'actionRevision': actionRevision,
    'stateVersion': stateVersion,
    'actionsOpen': actionsOpen,
    'actionsPhase': actionsPhase?.name,
    'actionsRound': actionsRound,
    'winner': winner?.name,
    'createdAt': createdAt.toIso8601String(),
    'globalAnnouncement': globalAnnouncement,
  };

  factory InteractiveSession.fromJson(Map<String, dynamic> json) =>
      InteractiveSession(
        id: json['id'] as String,
        closed: json['closed'] == true,
        hostUid: json['hostUid'] as String,
        status: SessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SessionStatus.waiting,
        ),
        phase: Phase.values.firstWhere(
          (e) => e.name == json['phase'],
          orElse: () => Phase.setup,
        ),
        round: json['round'] as int? ?? 1,
        actionRevision: (json['actionRevision'] as num?)?.toInt() ?? 0,
        stateVersion: (json['stateVersion'] as num?)?.toInt() ?? 0,
        actionsOpen: json['actionsOpen'] != false,
        actionsPhase: json['actionsPhase'] != null
            ? Phase.values.firstWhere(
                (phase) => phase.name == json['actionsPhase'],
                orElse: () => Phase.setup,
              )
            : null,
        actionsRound: (json['actionsRound'] as num?)?.toInt(),
        winner: json['winner'] != null
            ? Team.values.firstWhere((e) => e.name == json['winner'])
            : null,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        globalAnnouncement: json['globalAnnouncement'] as String?,
        sharedThemeId: json['sharedThemeId'] as String?,
        themeVersion: (json['themeVersion'] as num?)?.toInt(),
      );
}

class InteractiveSeat {
  final String id;
  final String playerName;
  final bool isAlive;
  final bool isKicked;
  final SeatStatus status;
  final String? linkedUid;
  final bool isCitizenSheikhRevealed;

  InteractiveSeat({
    required this.id,
    required this.playerName,
    required this.isAlive,
    this.isKicked = false,
    required this.status,
    this.linkedUid,
    this.isCitizenSheikhRevealed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerName': playerName,
    'isAlive': isAlive,
    'isKicked': isKicked,
    'status': status.name,
    'linkedUid': linkedUid,
    'isCitizenSheikhRevealed': isCitizenSheikhRevealed,
  };

  factory InteractiveSeat.fromJson(Map<String, dynamic> json) =>
      InteractiveSeat(
        id: json['id'] as String,
        playerName: json['playerName'] as String,
        isAlive: json['isAlive'] as bool? ?? true,
        isKicked: json['isKicked'] as bool? ?? false,
        status: SeatStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SeatStatus.unlinked,
        ),
        linkedUid: json['linkedUid'] as String?,
        isCitizenSheikhRevealed:
            json['isCitizenSheikhRevealed'] as bool? ?? false,
      );
}

class PlayerActionPrompt {
  final String type;
  final List<String> availableTargets;

  const PlayerActionPrompt({
    required this.type,
    required this.availableTargets,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'availableTargets': availableTargets,
  };

  factory PlayerActionPrompt.fromJson(Map<String, dynamic> json) =>
      PlayerActionPrompt(
        type: json['type'] as String,
        availableTargets: (json['availableTargets'] as List? ?? const [])
            .cast<String>(),
      );
}

class InteractiveSecret {
  final String id;
  final Role? role;
  final List<PlayerActionPrompt> requiredActions;
  final int? promptRevision;
  final String? privateResult;
  final bool hasSubmittedAction;
  final bool isSniper;
  final List<String> mafiaTeammates;

  InteractiveSecret({
    required this.id,
    this.role,
    this.requiredActions = const [],
    this.promptRevision,
    this.privateResult,
    this.hasSubmittedAction = false,
    this.isSniper = false,
    this.mafiaTeammates = const [],
  });

  // Legacy accessors keep older clients/data readable during rollout.
  String? get requiredActionType =>
      requiredActions.isEmpty ? null : requiredActions.first.type;
  List<String>? get availableTargets =>
      requiredActions.isEmpty ? null : requiredActions.first.availableTargets;

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role?.name,
    'promptRevision': promptRevision,
    'requiredActions': requiredActions
        .map((action) => action.toJson())
        .toList(),
    // A map lets security rules validate every published action/target
    // without relying on client UI checks or list iteration in rules.
    'allowedTargetsByAction': {
      for (final action in requiredActions)
        action.type: action.availableTargets,
    },
    'requiredActionType': requiredActionType,
    'availableTargets': availableTargets,
    'privateResult': privateResult,
    'hasSubmittedAction': hasSubmittedAction,
    'isSniper': isSniper,
    'mafiaTeammates': mafiaTeammates,
  };

  factory InteractiveSecret.fromJson(Map<String, dynamic> json) {
    final prompts = (json['requiredActions'] as List? ?? const [])
        .map(
          (value) => PlayerActionPrompt.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
    final legacyType = json['requiredActionType'] as String?;
    if (prompts.isEmpty && legacyType != null) {
      prompts.add(
        PlayerActionPrompt(
          type: legacyType,
          availableTargets: (json['availableTargets'] as List? ?? const [])
              .cast<String>(),
        ),
      );
    }

    return InteractiveSecret(
      id: json['id'] as String,
      promptRevision: (json['promptRevision'] as num?)?.toInt(),
      role: json['role'] != null
          ? Role.values.firstWhere((role) => role.name == json['role'])
          : null,
      requiredActions: prompts,
      privateResult: json['privateResult'] as String?,
      hasSubmittedAction: json['hasSubmittedAction'] as bool? ?? false,
      isSniper: json['isSniper'] as bool? ?? false,
      mafiaTeammates: (json['mafiaTeammates'] as List? ?? []).cast<String>(),
    );
  }
}

class JoinRequest {
  final String uid;
  final String seatId;
  final String displayName;
  final DateTime timestamp;

  JoinRequest({
    required this.uid,
    required this.seatId,
    required this.displayName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'seatId': seatId,
    'displayName': displayName,
    'timestamp': timestamp.toIso8601String(),
  };

  factory JoinRequest.fromJson(Map<String, dynamic> json) => JoinRequest(
    uid: json['uid'] as String,
    seatId: json['seatId'] as String,
    displayName: json['displayName'] as String,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class ActionRequest {
  final String id;
  final String uid;
  final String? seatId;
  final String actionType; // "vote", "investigation", etc.
  final String targetId;
  final int revision;
  final int submissionVersion;
  final DateTime timestamp;

  ActionRequest({
    required this.id,
    required this.uid,
    this.seatId,
    required this.actionType,
    required this.targetId,
    this.revision = 0,
    this.submissionVersion = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    if (seatId != null) 'seatId': seatId,
    'actionType': actionType,
    'targetId': targetId,
    'revision': revision,
    if (submissionVersion > 0) 'submissionVersion': submissionVersion,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActionRequest.fromJson(Map<String, dynamic> json) => ActionRequest(
    id: json['id'] as String,
    uid: json['uid'] as String,
    seatId: json['seatId'] as String?,
    actionType: json['actionType'] as String,
    targetId: json['targetId'] as String,
    revision: (json['revision'] as num?)?.toInt() ?? 0,
    submissionVersion: (json['submissionVersion'] as num?)?.toInt() ?? 0,
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}
