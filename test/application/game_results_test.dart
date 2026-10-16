import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/data/repositories/game_results_repository.dart';
import 'package:mafia_nightfall/data/repositories/player_stats_repository.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';

void main() {
  test(
    'unsafe player names produce distinct valid IDs and retain legacy keys',
    () {
      final names = ['hamza', 'حمزة', '/', '.', '..', '__encoded__Lw==', ''];
      final ids = names.map(playerStatsDocumentId).toList();
      expect(ids.toSet().length, names.length);
      expect(
        ids.every(
          (id) => id.isNotEmpty && !id.contains('/') && id != '.' && id != '..',
        ),
        true,
      );
      expect(ids.take(2), names.take(2));
    },
  );

  test('results count team wins and only actual first-night victims', () {
    final date = DateTime(2026);
    final state = GameState(
      id: 'g',
      winner: Team.citizens,
      players: [
        Player(id: 'm', name: 'mafia', role: Role.normalMafia, createdAt: date),
        Player(
          id: 'c',
          name: 'citizen',
          role: Role.goodCitizen,
          createdAt: date,
        ),
        Player(id: 'j', name: 'joker', role: Role.joker, createdAt: date),
      ],
      eventHistory: [
        for (final round in [1, 2, 3])
          GameEvent(
            id: '$round',
            gameId: 'g',
            round: round,
            phase: Phase.nightResolution,
            type: EventType.nightResolutionSummary,
            timestamp: date,
            metadata: {
              'assassinatedIds': [round == 2 ? 'c' : 'm'],
            },
          ),
      ],
    );
    final stats = resultStats(state);
    expect(stats['citizen'], {
      'gamesPlayed': 1,
      'mafiaWins': 0,
      'citizenWins': 1,
      'killedFirstNight': 1,
    });
    expect(stats['mafia']!['killedFirstNight'], 0);
    expect(stats['joker']!['citizenWins'], 0);
  });
}
