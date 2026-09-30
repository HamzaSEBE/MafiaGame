import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';

class VotingResult {
  final String? eliminatedPlayerId;
  final bool isTie;
  final Map<String, int> voteCounts;

  VotingResult({
    this.eliminatedPlayerId,
    required this.isTie,
    required this.voteCounts,
  });
}

class VotingEngine {
  static VotingResult calculateVotes(GameState state) {
    // 1. Get all votes for this round
    final votes = state.eventHistory.where((e) => 
      e.round == state.round && 
      e.type == EventType.vote
    ).toList();

    // 2. Count votes
    final voteCounts = <String, int>{};
    for (var vote in votes) {
      final targetId = vote.targetId!;
      final actor = state.getPlayerById(vote.actorId ?? '');
      
      int voteWeight = 1;
      if (actor != null && actor.isCitizenSheikhRevealed) {
        voteWeight = 3;
      }
      
      voteCounts[targetId] = (voteCounts[targetId] ?? 0) + voteWeight;
    }

    if (voteCounts.isEmpty) {
      return VotingResult(isTie: false, voteCounts: {});
    }

    // 3. Find highest votes
    int maxVotes = 0;
    for (var count in voteCounts.values) {
      if (count > maxVotes) {
        maxVotes = count;
      }
    }

    // 4. Find candidates with max votes
    final topCandidates = voteCounts.entries
        .where((e) => e.value == maxVotes)
        .map((e) => e.key)
        .toList();

    if (topCandidates.length > 1) {
      return VotingResult(isTie: true, voteCounts: voteCounts);
    } else {
      return VotingResult(
        eliminatedPlayerId: topCandidates.first,
        isTie: false,
        voteCounts: voteCounts,
      );
    }
  }

  static GameState applyElimination(GameState state, String eliminatedPlayerId) {
    final eliminatedPlayer = state.getPlayerById(eliminatedPlayerId);
    final isMafia = eliminatedPlayer?.role.team == Team.mafia;

    int newExecCount = state.correctMafiaExecutionsCount;
    if (isMafia) {
      newExecCount++;
    }

    final updatedPlayers = state.players.map((p) {
      if (p.id == eliminatedPlayerId) {
        return p.copyWith(isAlive: false);
      }
      return p;
    }).toList();

    final eliminationEvent = GameEvent(
      id: 'elim_${DateTime.now().millisecondsSinceEpoch}',
      gameId: state.id,
      round: state.round,
      phase: Phase.elimination,
      type: EventType.elimination,
      targetId: eliminatedPlayerId,
      timestamp: DateTime.now(),
    );
    
    // Check if we need to emit correct execution event
    List<GameEvent> newEvents = [eliminationEvent];
    if (isMafia && state.rules.victoryRules.correctMafiaExecutions) {
      newEvents.add(GameEvent(
        id: 'corr_exec_${DateTime.now().millisecondsSinceEpoch}',
        gameId: state.id,
        round: state.round,
        phase: Phase.elimination,
        type: EventType.vote, // Use metadata to distinguish, or we can use metadata on elimination
        timestamp: DateTime.now(),
        metadata: {'correctMafiaExecution': true},
      ));
    }

    return state.copyWith(
      players: updatedPlayers,
      eventHistory: [...state.eventHistory, ...newEvents],
      correctMafiaExecutionsCount: newExecCount,
    );
  }
}
