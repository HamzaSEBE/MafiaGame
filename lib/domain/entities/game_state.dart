import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';

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
  });

  GameState copyWith({
    String? id,
    Phase? phase,
    int? round,
    List<Player>? players,
    List<GameEvent>? eventHistory,
    Team? winner,
    GameRuleset? rules,
    int? initialMafiaCount,
    int? correctMafiaExecutionsCount,
    String? victoryReason,
  }) {
    return GameState(
      id: id ?? this.id,
      phase: phase ?? this.phase,
      round: round ?? this.round,
      players: players ?? this.players,
      eventHistory: eventHistory ?? this.eventHistory,
      winner: winner ?? this.winner,
      rules: rules ?? this.rules,
      initialMafiaCount: initialMafiaCount ?? this.initialMafiaCount,
      correctMafiaExecutionsCount: correctMafiaExecutionsCount ?? this.correctMafiaExecutionsCount,
      victoryReason: victoryReason ?? this.victoryReason,
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
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        id: json['id'] as String,
        phase: Phase.values.firstWhere((p) => p.name == json['phase'], orElse: () => Phase.setup),
        round: json['round'] as int? ?? 1,
        players: (json['players'] as List?)?.map((p) => Player.fromJson(p as Map<String, dynamic>)).toList() ?? [],
        eventHistory: (json['eventHistory'] as List?)?.map((e) => GameEvent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
        winner: json['winner'] != null ? Team.values.firstWhere((t) => t.name == json['winner']) : null,
        rules: json['rules'] != null ? GameRuleset.fromJson(json['rules']) : const GameRuleset(),
        initialMafiaCount: json['initialMafiaCount'] ?? 0,
        correctMafiaExecutionsCount: json['correctMafiaExecutionsCount'] ?? 0,
        victoryReason: json['victoryReason'],
      );

  List<Player> get alivePlayers => players.where((p) => p.isAlive).toList();
  List<Player> get deadPlayers => players.where((p) => !p.isAlive).toList();

  Player? getPlayerById(String id) {
    try {
      return players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<GameEvent> getEventsForRoundAndPhase(int round, Phase phase) {
    return eventHistory.where((e) => e.round == round && e.phase == phase).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GameState && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
