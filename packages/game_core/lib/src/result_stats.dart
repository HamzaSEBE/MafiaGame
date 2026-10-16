import 'entities/game_state.dart';
import 'enums/phase.dart';
import 'enums/role.dart';
import 'events/game_event.dart';

/// First-night statistics follow actual night summaries, excluding round-one
/// introductions. Pure calculation keeps the rules independently testable.
Map<String, Map<String, int>> resultStats(GameState state) {
  final summaries = state.eventHistory.where(
    (event) =>
        event.round > 1 &&
        event.phase == Phase.nightResolution &&
        event.type == EventType.nightResolutionSummary,
  );
  final rounds = summaries.map((event) => event.round);
  final firstRound = rounds.isEmpty
      ? null
      : rounds.reduce((a, b) => a < b ? a : b);
  final victims = summaries
      .where((event) => event.round == firstRound)
      .expand(
        (event) =>
            (event.metadata['assassinatedIds'] as List?)?.whereType<String>() ??
            const <String>[],
      )
      .toSet();
  return {
    for (final player in state.players)
      player.name: {
        'gamesPlayed': 1,
        'mafiaWins':
            state.winner == Team.mafia && player.role.team == Team.mafia
            ? 1
            : 0,
        // Preserve the established non-mafia win bucket for the joker.
        'citizenWins':
            state.winner != Team.mafia && state.winner == player.role.team
            ? 1
            : 0,
        'killedFirstNight': victims.contains(player.id) ? 1 : 0,
      },
  };
}
