import 'package:game_core/src/entities/game_state.dart';
import 'package:game_core/src/events/game_event.dart';
import 'package:game_core/src/enums/phase.dart';
import 'package:game_core/src/enums/role.dart';

class VotingResult {
  final String? eliminatedPlayerId;
  final bool isTie;
  final Map<String, int> voteCounts;

  VotingResult({
    this.eliminatedPlayerId,
    required this.isTie,
    required this.voteCounts,
  });

  List<String> get tiedPlayerIds {
    if (!isTie || voteCounts.isEmpty) return const [];
    final highest = voteCounts.values.reduce((a, b) => a > b ? a : b);
    return voteCounts.entries
        .where((entry) => entry.value == highest)
        .map((entry) => entry.key)
        .toList();
  }
}

class VotingEngine {
  static VotingResult calculateVotes(GameState state) {
    final playersById = {for (final player in state.players) player.id: player};
    // A retried/changed ballot replaces the earlier ballot from this voter.
    // Old saves also contain execution markers with type=vote and no target.
    final votesByActor = <String, GameEvent>{};
    for (final event in state.eventHistory) {
      if (event.gameId != state.id ||
          event.round != state.round ||
          event.phase != Phase.voting ||
          event.type != EventType.vote) {
        continue;
      }
      final actor = playersById[event.actorId];
      final target = playersById[event.targetId];
      if (actor == null ||
          target == null ||
          !actor.isAlive ||
          !target.isAlive ||
          actor.id == target.id) {
        continue;
      }
      votesByActor[actor.id] = event;
    }

    // 2. Count votes
    final voteCounts = <String, int>{};
    for (var vote in votesByActor.values) {
      final targetId = vote.targetId!;
      final actor = playersById[vote.actorId]!;

      int voteWeight = 1;
      if (actor.role == Role.citizensSheikh && actor.isCitizenSheikhRevealed) {
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

  static GameState applyElimination(
    GameState state,
    String eliminatedPlayerId, {
    DateTime? timestamp,
  }) {
    final eliminatedPlayer = state.getPlayerById(eliminatedPlayerId);
    if (eliminatedPlayer == null || !eliminatedPlayer.isAlive) return state;
    // Resolution is one operation per round, including repeated UI callbacks.
    if (state.eventHistory.any(
      (event) =>
          event.gameId == state.id &&
          event.round == state.round &&
          event.type == EventType.elimination,
    )) {
      return state;
    }
    final isMafia = eliminatedPlayer.role.team == Team.mafia;

    int newExecCount = state.correctMafiaExecutionsCount;
    if (isMafia) {
      newExecCount++;
    }

    final updatedPlayers = state.players.map((p) {
      if (p.id == eliminatedPlayerId) {
        return p.copyWith(isAlive: false, isSilenced: false);
      }
      return p;
    }).toList();

    final eliminationEvent = GameEvent(
      id: 'elim_${state.id}_${state.round}',
      gameId: state.id,
      round: state.round,
      phase: Phase.elimination,
      type: EventType.elimination,
      targetId: eliminatedPlayerId,
      timestamp: timestamp ?? DateTime.now(),
      metadata: {'correctMafiaExecution': isMafia},
    );

    return state.copyWith(
      players: updatedPlayers,
      eventHistory: [...state.eventHistory, eliminationEvent],
      correctMafiaExecutionsCount: newExecCount,
    );
  }
}
