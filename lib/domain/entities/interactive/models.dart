import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';

enum SessionStatus { waiting, active, finished }
enum SeatStatus { unlinked, requested, linked }

class InteractiveSession {
  final String id;
  final String hostUid;
  final SessionStatus status;
  final Phase phase;
  final int round;
  final Team? winner;
  final DateTime createdAt;

  InteractiveSession({
    required this.id,
    required this.hostUid,
    required this.status,
    required this.phase,
    required this.round,
    this.winner,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'hostUid': hostUid,
        'status': status.name,
        'phase': phase.name,
        'round': round,
        'winner': winner?.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InteractiveSession.fromJson(Map<String, dynamic> json) => InteractiveSession(
        id: json['id'] as String,
        hostUid: json['hostUid'] as String,
        status: SessionStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => SessionStatus.waiting),
        phase: Phase.values.firstWhere((e) => e.name == json['phase'], orElse: () => Phase.setup),
        round: json['round'] as int? ?? 1,
        winner: json['winner'] != null ? Team.values.firstWhere((e) => e.name == json['winner']) : null,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class InteractiveSeat {
  final String id;
  final String playerName;
  final bool isAlive;
  final SeatStatus status;
  final String? linkedUid;

  InteractiveSeat({
    required this.id,
    required this.playerName,
    required this.isAlive,
    required this.status,
    this.linkedUid,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerName': playerName,
        'isAlive': isAlive,
        'status': status.name,
        'linkedUid': linkedUid,
      };

  factory InteractiveSeat.fromJson(Map<String, dynamic> json) => InteractiveSeat(
        id: json['id'] as String,
        playerName: json['playerName'] as String,
        isAlive: json['isAlive'] as bool? ?? true,
        status: SeatStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => SeatStatus.unlinked),
        linkedUid: json['linkedUid'] as String?,
      );
}

class InteractiveSecret {
  final String id;
  final Role? role;
  final String? requiredActionType; // e.g. "vote", "investigation", "assassination"
  final List<String>? availableTargets; 
  final bool hasSubmittedAction;

  InteractiveSecret({
    required this.id,
    this.role,
    this.requiredActionType,
    this.availableTargets,
    this.hasSubmittedAction = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role?.name,
        'requiredActionType': requiredActionType,
        'availableTargets': availableTargets,
        'hasSubmittedAction': hasSubmittedAction,
      };

  factory InteractiveSecret.fromJson(Map<String, dynamic> json) => InteractiveSecret(
        id: json['id'] as String,
        role: json['role'] != null ? Role.values.firstWhere((e) => e.name == json['role']) : null,
        requiredActionType: json['requiredActionType'] as String?,
        availableTargets: (json['availableTargets'] as List?)?.map((e) => e as String).toList(),
        hasSubmittedAction: json['hasSubmittedAction'] as bool? ?? false,
      );
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
  final String actionType; // "vote", "investigation", etc.
  final String targetId;
  final DateTime timestamp;

  ActionRequest({
    required this.id,
    required this.uid,
    required this.actionType,
    required this.targetId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'uid': uid,
        'actionType': actionType,
        'targetId': targetId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ActionRequest.fromJson(Map<String, dynamic> json) => ActionRequest(
        id: json['id'] as String,
        uid: json['uid'] as String,
        actionType: json['actionType'] as String,
        targetId: json['targetId'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      );
}
