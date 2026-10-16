import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/core/error/game_error.dart';
import 'package:mafia_nightfall/domain/engine/citizen_boy_engine.dart';
import 'package:mafia_nightfall/domain/engine/night_resolution_engine.dart';
import 'package:mafia_nightfall/domain/engine/victory_engine.dart';
import 'package:mafia_nightfall/domain/engine/voting_engine.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/rules/game_ruleset.dart';

final date = DateTime(2026);
Player player(String id, Role role, {bool alive = true, bool sniper = false}) =>
    Player(
      id: id,
      name: id,
      role: role,
      isAlive: alive,
      hasSniper: sniper,
      createdAt: date,
    );
GameEvent event(
  String id,
  EventType type, {
  String? actor,
  String? target,
  Phase phase = Phase.night,
  int round = 2,
  String game = 'g',
  Map<String, dynamic> metadata = const {},
}) => GameEvent(
  id: id,
  gameId: game,
  round: round,
  phase: phase,
  type: type,
  actorId: actor,
  targetId: target,
  timestamp: date,
  metadata: metadata,
);

class SeededOrchestrator extends GameOrchestrator {
  SeededOrchestrator(this.initial);
  final GameState initial;
  @override
  GameState build() => initial;
}

ProviderContainer containerFor(GameState initial) => ProviderContainer(
  overrides: [
    gameOrchestratorProvider.overrideWith(() => SeededOrchestrator(initial)),
  ],
);

void main() {
  final players = [
    player('m', Role.normalMafia),
    player('c', Role.goodCitizen),
    player('d', Role.citizensGirl),
    player('s', Role.citizensSheikh),
    player('b', Role.citizensBoy),
  ];

  test(
    'ballots ignore malformed markers and replace repeated voter ballots',
    () {
      final state = GameState(
        id: 'g',
        round: 2,
        phase: Phase.voting,
        players: players,
        eventHistory: [
          event(
            'v1',
            EventType.vote,
            actor: 'c',
            target: 'm',
            phase: Phase.voting,
          ),
          event(
            'v2',
            EventType.vote,
            actor: 'c',
            target: 'd',
            phase: Phase.voting,
          ),
          event('marker', EventType.vote, phase: Phase.voting),
          event(
            'foreign',
            EventType.vote,
            actor: 's',
            target: 'm',
            game: 'other',
            phase: Phase.voting,
          ),
          event(
            'invalid',
            EventType.vote,
            actor: 'b',
            target: 'missing',
            phase: Phase.voting,
          ),
        ],
      );
      expect(VotingEngine.calculateVotes(state).voteCounts, {'d': 1});
    },
  );

  test('revealed Sheikh has three votes and dead voters have none', () {
    final state = GameState(
      id: 'g',
      round: 2,
      phase: Phase.voting,
      players: [
        players[0],
        players[1].copyWith(isAlive: false),
        players[3].copyWith(isCitizenSheikhRevealed: true),
      ],
      eventHistory: [
        event(
          'v1',
          EventType.vote,
          actor: 's',
          target: 'm',
          phase: Phase.voting,
        ),
        event(
          'v2',
          EventType.vote,
          actor: 'c',
          target: 'm',
          phase: Phase.voting,
        ),
      ],
    );
    expect(VotingEngine.calculateVotes(state).voteCounts, {'m': 3});
  });

  test('repeated elimination cannot double count or kill another player', () {
    final state = GameState(
      id: 'g',
      round: 2,
      phase: Phase.voting,
      players: players,
    );
    final once = VotingEngine.applyElimination(state, 'm');
    expect(once.correctMafiaExecutionsCount, 1);
    expect(identical(VotingEngine.applyElimination(once, 'm'), once), true);
    expect(identical(VotingEngine.applyElimination(once, 'c'), once), true);
  });

  test('night resolution is idempotent and ignores other games', () {
    final state = GameState(
      id: 'g',
      round: 2,
      phase: Phase.night,
      players: players,
      eventHistory: [
        event('kill', EventType.assassination, actor: 'm', target: 'c'),
        event(
          'foreign',
          EventType.assassination,
          actor: 'm',
          target: 'd',
          game: 'other',
        ),
      ],
    );
    final once = NightResolutionEngine.resolve(state, state.rules);
    expect(once.getPlayerById('c')!.isAlive, false);
    expect(once.getPlayerById('d')!.isAlive, true);
    expect(
      identical(NightResolutionEngine.resolve(once, state.rules), once),
      true,
    );
  });

  test('boy is found when he is the second night victim', () {
    final state = GameState(
      id: 'g',
      round: 2,
      phase: Phase.triggeredAbility,
      players: [
        player('c', Role.goodCitizen, alive: false),
        player('b', Role.citizensBoy, alive: false),
        player('m', Role.normalMafia),
      ],
      eventHistory: [
        event(
          'summary',
          EventType.nightResolutionSummary,
          phase: Phase.nightResolution,
          metadata: {
            'assassinatedIds': ['c', 'b'],
          },
        ),
      ],
    );
    expect(CitizenBoyEngine.pendingActor(state)!.id, 'b');
    expect(
      () => CitizenBoyEngine.applyRetaliation(state, 'c', 'm'),
      throwsA(isA<RoleCannotActException>()),
    );
    final once = CitizenBoyEngine.applyRetaliation(state, 'b', 'm');
    expect(
      identical(CitizenBoyEngine.applyRetaliation(once, 'b', 'm'), once),
      true,
    );
  });

  test(
    'night action edits replace rather than consume another lifetime use',
    () {
      final state = GameState(
        id: 'g',
        round: 2,
        phase: Phase.night,
        players: players,
      );
      final container = containerFor(state);
      addTearDown(container.dispose);
      final controller = container.read(gameOrchestratorProvider.notifier);
      controller.submitNightAction(
        actorId: 'd',
        targetId: 'c',
        type: EventType.protection,
      );
      controller.submitNightAction(
        actorId: 'd',
        targetId: 'c',
        type: EventType.protection,
      );
      expect(container.read(gameOrchestratorProvider).eventHistory.length, 1);
      controller.submitNightAction(
        actorId: 'd',
        targetId: 'b',
        type: EventType.protection,
      );
      expect(
        container.read(gameOrchestratorProvider).eventHistory.single.targetId,
        'b',
      );
    },
  );

  test('sniper cannot belong to mafia after swapping or reshuffling', () {
    const rules = GameRuleset(abilityRules: AbilityRules(sniper: true));
    final container = containerFor(
      GameState(
        id: 'g',
        phase: Phase.roleReveal,
        rules: rules,
        players: [
          player('m', Role.normalMafia),
          player('c', Role.goodCitizen, sniper: true),
          player('d', Role.citizensGirl),
        ],
      ),
    );
    addTearDown(container.dispose);
    final controller = container.read(gameOrchestratorProvider.notifier);
    controller.swapPlayerRoles('m', 'c');
    for (var i = 0; i < 10; i++) {
      final sniper = container
          .read(gameOrchestratorProvider)
          .players
          .where((p) => p.hasSniper)
          .toList();
      expect(sniper.length, 1);
      expect(sniper.single.role.team, Team.citizens);
      controller.shuffleAssignedRoles();
    }
  });

  test('retaliation happens before a parity victory', () {
    final container = containerFor(
      GameState(
        id: 'g',
        round: 2,
        phase: Phase.night,
        players: [
          player('m', Role.normalMafia),
          player('c', Role.goodCitizen),
          player('b', Role.citizensBoy),
        ],
        eventHistory: [
          event('kill', EventType.assassination, actor: 'm', target: 'b'),
        ],
      ),
    );
    addTearDown(container.dispose);
    final controller = container.read(gameOrchestratorProvider.notifier);
    controller.resolveNight();
    expect(
      container.read(gameOrchestratorProvider).phase,
      Phase.triggeredAbility,
    );
    expect(container.read(gameOrchestratorProvider).winner, isNull);
    controller.citizenBoyRetaliation(
      actorId: 'b',
      targetId: 'm',
      nextPhase: Phase.day,
    );
    expect(container.read(gameOrchestratorProvider).winner, Team.citizens);
  });

  test('unachievable exact execution target finishes the game', () {
    final state = GameState(
      id: 'g',
      round: 2,
      players: [player('m', Role.normalMafia), player('c', Role.goodCitizen)],
      rules: const GameRuleset(
        victoryRules: VictoryRules(
          mode: VictoryMode.exactMafiaExecutions,
          requiredCorrectExecutions: 2,
        ),
      ),
    );
    expect(VictoryEngine.evaluate(state), VictoryStatus.mafiaWin);
    expect(
      VictoryEngine.evaluate(state.copyWith(correctMafiaExecutionsCount: 2)),
      VictoryStatus.citizensWin,
    );
  });
}
