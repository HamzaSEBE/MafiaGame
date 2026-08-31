import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';
import 'package:mafia_nightfall/domain/engine/night_resolution_engine.dart';
import 'package:mafia_nightfall/domain/engine/voting_engine.dart';
import 'package:mafia_nightfall/domain/engine/victory_engine.dart';
import 'package:mafia_nightfall/domain/engine/citizen_boy_engine.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:uuid/uuid.dart';

// ─── Manual Riverpod Provider (no code generation needed) ────────────────────

final gameOrchestratorProvider =
    NotifierProvider<GameOrchestrator, GameState>(GameOrchestrator.new);

class GameOrchestrator extends Notifier<GameState> {
  final GameRuleset _ruleset = const GameRuleset();

  @override
  GameState build() {
    return GameState(id: const Uuid().v4());
  }

  // ────────────────────────────────────────────
  // SETUP
  // ────────────────────────────────────────────

  void addPlayer(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final player = Player(
      id: const Uuid().v4(),
      name: trimmed,
      role: Role.goodCitizen, // placeholder until assigned
      createdAt: DateTime.now(),
    );
    state = state.copyWith(players: [...state.players, player]);
  }

  void removePlayer(String playerId) {
    state = state.copyWith(
      players: state.players.where((p) => p.id != playerId).toList(),
    );
  }

  /// Shuffle and assign roles based on [roleConfig] (Map<Role, count>).
  /// Returns an error string if the total doesn't match player count, else null.
  String? assignRoles(Map<Role, int> roleConfig) {
    final totalRoles = roleConfig.values.fold(0, (a, b) => a + b);
    if (totalRoles != state.players.length) {
      return 'عدد الأدوار ($totalRoles) لا يساوي عدد اللاعبين (${state.players.length})';
    }

    // Build the roles list
    final List<Role> roles = [];
    for (final entry in roleConfig.entries) {
      for (int i = 0; i < entry.value; i++) {
        roles.add(entry.key);
      }
    }

    // Shuffle
    roles.shuffle(Random.secure());

    // Assign to players
    final updatedPlayers = List<Player>.from(state.players);
    for (int i = 0; i < updatedPlayers.length; i++) {
      updatedPlayers[i] = updatedPlayers[i].copyWith(role: roles[i]);
    }

    state = state.copyWith(
      players: updatedPlayers,
      phase: Phase.roleReveal,
    );
    return null; // success
  }

  // ────────────────────────────────────────────
  // NIGHT ACTIONS
  // ────────────────────────────────────────────

  void submitNightAction({
    required String actorId,
    required String targetId,
    required EventType type,
  }) {
    final event = GameEvent(
      id: const Uuid().v4(),
      gameId: state.id,
      round: state.round,
      phase: Phase.night,
      type: type,
      actorId: actorId,
      targetId: targetId,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(eventHistory: [...state.eventHistory, event]);
  }

  void undoLastNightAction() {
    if (state.eventHistory.isEmpty) return;
    
    // Remove the most recent event if it belongs to the current night round
    final lastEvent = state.eventHistory.last;
    if (lastEvent.phase == Phase.night && lastEvent.round == state.round) {
      final updatedHistory = List<GameEvent>.from(state.eventHistory)..removeLast();
      state = state.copyWith(eventHistory: updatedHistory);
    }
  }

  void resolveNight() {
    var nextState = NightResolutionEngine.resolve(state, _ruleset);
    
    // Find who was assassinated
    final resolutionEvent = nextState.eventHistory.lastWhere((e) => e.type == EventType.nightResolutionSummary);
    final assassinatedIds = List<String>.from(resolutionEvent.metadata?['assassinatedIds'] ?? []);
    
    final victoryStatus = VictoryEngine.evaluate(nextState);
    if (victoryStatus != VictoryStatus.continueGame) {
      final winner = victoryStatus == VictoryStatus.mafiaWin ? Team.mafia : Team.citizens;
      nextState = nextState.copyWith(phase: Phase.winCheck, winner: winner);
    } else if (assassinatedIds.isNotEmpty && CitizenBoyEngine.shouldTriggerAbility(nextState, assassinatedIds.first)) {
      nextState = nextState.copyWith(phase: Phase.triggeredAbility);
    } else {
      nextState = nextState.copyWith(phase: Phase.day);
    }
    state = nextState;
  }

  // ────────────────────────────────────────────
  // VOTING
  // ────────────────────────────────────────────

  void startVoting() {
    state = state.copyWith(phase: Phase.voting);
  }

  void submitFinalVotes(Map<String, String> finalVotes) {
    // Clear any existing votes for this round just in case
    final filteredEvents = state.eventHistory
        .where((e) => !(e.round == state.round && e.type == EventType.vote))
        .toList();
        
    final newEvents = finalVotes.entries.map((e) => GameEvent(
      id: const Uuid().v4(),
      gameId: state.id,
      round: state.round,
      phase: Phase.voting,
      type: EventType.vote,
      actorId: e.key,
      targetId: e.value,
      timestamp: DateTime.now(),
    )).toList();
    
    state = state.copyWith(eventHistory: [...filteredEvents, ...newEvents]);
  }

  Map<String, dynamic> resolveVote() {
    final result = VotingEngine.calculateVotes(state);
    if (result.isTie) {
      return {'isTie': true, 'tiedPlayers': result.voteCounts.keys.toList()};
    }
    if (result.eliminatedPlayerId != null) {
      var nextState = VotingEngine.applyElimination(state, result.eliminatedPlayerId!);
      final victoryStatus = VictoryEngine.evaluate(nextState);
      if (victoryStatus != VictoryStatus.continueGame) {
        final winner = victoryStatus == VictoryStatus.mafiaWin ? Team.mafia : Team.citizens;
        nextState = nextState.copyWith(phase: Phase.winCheck, winner: winner);
      } else if (CitizenBoyEngine.shouldTriggerAbility(nextState, result.eliminatedPlayerId!)) {
        nextState = nextState.copyWith(phase: Phase.triggeredAbility);
      } else {
        nextState = nextState.copyWith(phase: Phase.elimination);
      }
      state = nextState;
      return {'isTie': false, 'eliminatedId': result.eliminatedPlayerId};
    }
    return {'isTie': false, 'eliminatedId': null};
  }

  void skipElimination() {
    state = state.copyWith(phase: Phase.night, round: state.round + 1);
  }

  void revote() {
    final filteredEvents = state.eventHistory
        .where((e) => !(e.round == state.round && e.type == EventType.vote))
        .toList();
    state = state.copyWith(eventHistory: filteredEvents, phase: Phase.voting);
  }

  void citizenBoyRetaliation({required String actorId, required String targetId, required Phase nextPhase}) {
    var nextState = CitizenBoyEngine.applyRetaliation(state, actorId, targetId);
    final victoryStatus = VictoryEngine.evaluate(nextState);
    if (victoryStatus != VictoryStatus.continueGame) {
      final winner = victoryStatus == VictoryStatus.mafiaWin ? Team.mafia : Team.citizens;
      nextState = nextState.copyWith(phase: Phase.winCheck, winner: winner);
    } else {
      if (nextPhase == Phase.night) {
        nextState = nextState.copyWith(phase: Phase.night, round: state.round + 1);
      } else {
        nextState = nextState.copyWith(phase: nextPhase);
      }
    }
    state = nextState;
  }

  void advanceToNight() {
    state = state.copyWith(phase: Phase.night, round: state.round + 1);
  }

  void resetGame() {
    state = GameState(id: const Uuid().v4());
  }
}
