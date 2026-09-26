import 'package:mafia_nightfall/domain/enums/phase.dart';

enum EventType {
  assassination,
  silence,
  investigation,
  protection,
  vote,
  elimination,
  citizenBoyRetaliation,
  nightResolutionSummary,
}

class GameEvent {
  final String id;
  final String gameId;
  final int round;
  final Phase phase;
  final EventType type;
  final String? actorId;
  final String? targetId;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const GameEvent({
    required this.id,
    required this.gameId,
    required this.round,
    required this.phase,
    required this.type,
    this.actorId,
    this.targetId,
    required this.timestamp,
    this.metadata = const {},
  });

  GameEvent copyWith({
    String? id,
    String? gameId,
    int? round,
    Phase? phase,
    EventType? type,
    String? actorId,
    String? targetId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return GameEvent(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      round: round ?? this.round,
      phase: phase ?? this.phase,
      type: type ?? this.type,
      actorId: actorId ?? this.actorId,
      targetId: targetId ?? this.targetId,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'round': round,
        'phase': phase.name,
        'type': type.name,
        'actorId': actorId,
        'targetId': targetId,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
        id: json['id'] as String,
        gameId: json['gameId'] as String,
        round: json['round'] as int,
        phase: Phase.values.firstWhere((p) => p.name == json['phase'], orElse: () => Phase.setup),
        type: EventType.values.firstWhere((t) => t.name == json['type'], orElse: () => EventType.nightResolutionSummary),
        actorId: json['actorId'] as String?,
        targetId: json['targetId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GameEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
