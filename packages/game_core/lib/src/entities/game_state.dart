import 'package:game_core/src/enums/phase.dart';
import 'package:game_core/src/entities/player.dart';
import 'package:game_core/src/enums/team.dart';
import 'package:game_core/src/events/game_event.dart';
import 'package:game_core/src/rules/game_ruleset.dart';

const _unset = Object();

class GameState {
  final String id;
  final Phase phase;
  final int round;
  final List<Player> players;
  final List<GameEvent> eventHistory;
  final Team? winner;
  final GameRuleset rules;
  final int initialMafiaCount;
  final int correctMafiaExecutionsCount;
  final String? victoryReason;
  final DateTime? discussionDeadlineAt;
  final int discussionRemainingSeconds;
  final bool discussionPaused;

  const GameState({
    required this.id,
    this.phase = Phase.setup,
    this.round = 1,
    this.players = const [],
    this.eventHistory = const [],
    this.winner,
    this.rules = const GameRuleset(),
    this.initialMafiaCount = 0,
    this.correctMafiaExecutionsCount = 0,
    this.victoryReason,
    this.discussionDeadlineAt,
    this.discussionRemainingSeconds = 300,
    this.discussionPaused = false,
  });

  GameState copyWith({
    String? id,
    Phase? phase,
    int? round,
    List<Player>? players,
    List<GameEvent>? eventHistory,
    Object? winner = _unset,
    GameRuleset? rules,
    int? initialMafiaCount,
    int? correctMafiaExecutionsCount,
    Object? victoryReason = _unset,
    Object? discussionDeadlineAt = _unset,
    int? discussionRemainingSeconds,
    bool? discussionPaused,
  }) {
    return GameState(
      discussionDeadlineAt: identical(discussionDeadlineAt, _unset)
          ? this.discussionDeadlineAt
          : discussionDeadlineAt as DateTime?,
      discussionRemainingSeconds:
          discussionRemainingSeconds ?? this.discussionRemainingSeconds,
      discussionPaused: discussionPaused ?? this.discussionPaused,
      id: id ?? this.id,
      phase: phase ?? this.phase,
      round: round ?? this.round,
      players: List.unmodifiable(players ?? this.players),
      eventHistory: List.unmodifiable(eventHistory ?? this.eventHistory),
      winner: identical(winner, _unset) ? this.winner : winner as Team?,
      rules: rules ?? this.rules,
      initialMafiaCount: initialMafiaCount ?? this.initialMafiaCount,
      correctMafiaExecutionsCount:
          correctMafiaExecutionsCount ?? this.correctMafiaExecutionsCount,
      victoryReason: identical(victoryReason, _unset)
          ? this.victoryReason
          : victoryReason as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phase': phase.name,
    'round': round,
    'players': players.map((p) => p.toJson()).toList(),
    'eventHistory': eventHistory.map((e) => e.toJson()).toList(),
    'winner': winner?.name,
    'rules': rules.toJson(),
    'initialMafiaCount': initialMafiaCount,
    'correctMafiaExecutionsCount': correctMafiaExecutionsCount,
    'victoryReason': victoryReason,
    'discussionDeadlineAt': discussionDeadlineAt?.toUtc().toIso8601String(),
    'discussionRemainingSeconds': discussionRemainingSeconds,
    'discussionPaused': discussionPaused,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    discussionDeadlineAt: DateTime.tryParse(
      json['discussionDeadlineAt'] as String? ?? '',
    ),
    discussionRemainingSeconds:
        json['discussionRemainingSeconds'] as int? ?? 300,
    discussionPaused: json['discussionPaused'] as bool? ?? false,
    id: json['id'] as String,
    phase: Phase.values.firstWhere(
      (p) => p.name == json['phase'],
      orElse: () => Phase.setup,
    ),
    round: json['round'] as int? ?? 1,
    players:
        (json['players'] as List?)
            ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [],
    eventHistory:
        (json['eventHistory'] as List?)
            ?.map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    winner: json['winner'] != null
        ? Team.values.firstWhere((t) => t.name == json['winner'])
        : null,
    rules: json['rules'] != null
        ? GameRuleset.fromJson(json['rules'])
        : const GameRuleset(),
    initialMafiaCount: json['initialMafiaCount'] ?? 0,
    correctMafiaExecutionsCount: json['correctMafiaExecutionsCount'] ?? 0,
    victoryReason: json['victoryReason'],
  );

  List<Player> get alivePlayers =>
      players.where((p) => p.isAlive && !p.isKicked).toList();
  List<Player> get deadPlayers =>
      players.where((p) => !p.isAlive && !p.isKicked).toList();

  Player? getPlayerById(String id) {
    try {
      return players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<GameEvent> getEventsForRoundAndPhase(int round, Phase phase) {
    return eventHistory
        .where((e) => e.round == round && e.phase == phase)
        .toList();
  }
}
