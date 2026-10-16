import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/application/interactive_prompts.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';

void main() {
  final date = DateTime(2026);
  final players = [
    Player(
      id: 'doctor',
      name: 'doctor',
      role: Role.citizensGirl,
      createdAt: date,
    ),
    Player(
      id: 'target',
      name: 'target',
      role: Role.goodCitizen,
      createdAt: date,
    ),
    Player(id: 'mafia', name: 'mafia', role: Role.normalMafia, createdAt: date),
  ];
  final used = GameEvent(
    id: 'used',
    gameId: 'g',
    round: 2,
    phase: Phase.night,
    type: EventType.protection,
    actorId: 'doctor',
    targetId: 'target',
    timestamp: date,
  );
  for (final limit in [1, 2, -1]) {
    test('interactive targets respect configured protection limit $limit', () {
      final state = GameState(
        id: 'g',
        round: 3,
        phase: Phase.night,
        players: players,
        eventHistory: [used],
        rules: GameRuleset(
          abilityRules: AbilityRules(protectionTargetLimit: limit),
        ),
      );
      final targets = InteractivePrompts.night(
        state,
      )['doctor']!.firstWhere((p) => p.type == 'protection').availableTargets;
      expect(targets.contains('target'), limit != 1);
    });
  }
  test('disabled sniper and dead players receive no sniper prompts', () {
    final state = GameState(
      id: 'g',
      round: 3,
      phase: Phase.night,
      players: [
        players[0].copyWith(hasSniper: true),
        players[1].copyWith(isAlive: false),
        players[2],
      ],
    );
    final prompts = InteractivePrompts.night(state);
    expect(prompts.containsKey('target'), false);
    expect(prompts['doctor']!.any((p) => p.type == 'sniperKill'), false);
  });
  test('revisions discard ballots from before a revote', () {
    final actions = [
      for (final rev in [4, 5])
        ActionRequest(
          id: 'p_vote',
          uid: 'p',
          seatId: 'seat',
          actionType: 'vote',
          targetId: 'target',
          revision: rev,
          timestamp: date,
        ),
    ];
    expect(InteractivePrompts.currentActions(actions, null), isEmpty);
    expect(InteractivePrompts.currentActions(actions, 5).single.revision, 5);
  });
}
