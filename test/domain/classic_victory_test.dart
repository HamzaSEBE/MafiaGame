import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

final now = DateTime(2026, 10, 11);
Player player(String id, Role role, {bool sniper = false, bool alive = true}) =>
    Player(
      id: id,
      name: id,
      role: role,
      hasSniper: sniper,
      isAlive: alive,
      createdAt: now,
    );
GameEvent action(
  EventType type,
  String actor,
  String target, {
  String gameId = 'parity',
  int round = 1,
}) => GameEvent(
  id: '$gameId-$type-$actor-$target-$round',
  gameId: gameId,
  round: round,
  phase: Phase.night,
  type: type,
  actorId: actor,
  targetId: target,
  timestamp: now,
);
GameState parity({bool sniper = true, int protectionLimit = 1}) => GameState(
  id: 'parity',
  phase: Phase.night,
  round: 2,
  initialMafiaCount: 2,
  rules: GameRuleset(
    abilityRules: AbilityRules(
      sniper: sniper,
      protectionTargetLimit: protectionLimit,
    ),
  ),
  players: [
    player('m1', Role.normalMafia),
    player('m2', Role.normalMafia),
    player('s', Role.goodCitizen, sniper: true),
    player('d', Role.citizensGirl),
  ],
);
List<GameEvent> spentProtections(GameState state) => [
  for (final p in state.alivePlayers) action(EventType.protection, 'd', p.id),
];

void main() {
  test(
    'interactive reducer publishes final-night prompts only with both abilities',
    () {
      for (final enabled in [false, true]) {
        final initial = parity(sniper: enabled).copyWith(
          phase: Phase.voting,
          players: [...parity().players, player('extra', Role.goodCitizen)],
        );
        final afterVote = ServerReducer.transition(
          initial,
          'closeVote',
          [
            for (final actor in ['m1', 's', 'd'])
              {'seatId': actor, 'actionType': 'vote', 'targetId': 'extra'},
          ],
          now,
          'vote',
        );
        expect(afterVote.phase, enabled ? Phase.elimination : Phase.winCheck);
        expect(afterVote.winner, enabled ? isNull : Team.mafia);
        if (!enabled) {
          final projection = ServerReducer.project(afterVote, 4);
          expect(projection['winner'], 'mafia');
          expect(projection['actionsPhase'], isNull);
          continue;
        }
        final night = ServerReducer.transition(
          afterVote,
          'openNightActions',
          [],
          now,
          'open',
        );
        final projection = ServerReducer.project(night, 5);
        expect(projection['actionsPhase'], 'night');
        final prompts = InteractivePrompts.night(night);
        expect(prompts['s']!.any((p) => p.type == 'sniperKill'), isTrue);
        expect(prompts['d']!.any((p) => p.type == 'protection'), isTrue);
        final afterNight = ServerReducer.transition(
          night,
          'closeNight',
          [
            {'seatId': 'm1', 'actionType': 'assassination', 'targetId': 's'},
            {'seatId': 'd', 'actionType': 'protection', 'targetId': 's'},
            {'seatId': 's', 'actionType': 'sniperKill', 'targetId': 'm1'},
          ],
          now,
          'close',
        );
        expect(afterNight.phase, Phase.day);
        expect(afterNight.winner, isNull);
        expect(afterNight.getPlayerById('s')!.isAlive, isTrue);
        expect(afterNight.getPlayerById('m1')!.isAlive, isFalse);
      }
    },
  );
  test(
    'default classic wins at living faction parity without enabled sniper',
    () {
      expect(const GameRuleset().victoryRules.mode, VictoryMode.classic);
      expect(const GameRuleset().abilityRules.sniper, isFalse);
      expect(
        VictoryEngine.evaluate(parity(sniper: false)),
        VictoryStatus.mafiaWin,
      );
    },
  );
  test(
    'both unused citizen sniper and available protection grant parity chance',
    () {
      expect(VictoryEngine.evaluate(parity()), VictoryStatus.continueGame);
    },
  );
  test('citizens ahead continue even without either ability', () {
    final state = parity(sniper: false);
    expect(
      VictoryEngine.evaluate(
        state.copyWith(
          players: [...state.players, player('c', Role.goodCitizen)],
        ),
      ),
      VictoryStatus.continueGame,
    );
  });
  test('outnumbered citizens lose even with both abilities', () {
    final state = parity();
    expect(
      VictoryEngine.evaluate(
        state.copyWith(
          players: [...state.players, player('m3', Role.normalMafia)],
        ),
      ),
      VictoryStatus.mafiaWin,
    );
  });
  test('living Joker does not postpone classic faction parity', () {
    final state = parity(sniper: false);
    expect(
      VictoryEngine.evaluate(
        state.copyWith(players: [...state.players, player('j', Role.joker)]),
      ),
      VictoryStatus.mafiaWin,
    );
  });
  test('dead players do not count and dead doctor cannot grant a chance', () {
    final state = parity();
    expect(
      VictoryEngine.evaluate(
        state.copyWith(
          players: [
            for (final p in state.players)
              p.copyWith(isAlive: p.id != 'd' && p.id != 'm2'),
          ],
        ),
      ),
      VictoryStatus.mafiaWin,
    );
  });
  test('dead sniper cannot grant a chance', () {
    final state = parity();
    expect(
      VictoryEngine.evaluate(
        state.copyWith(
          players: [
            for (final p in state.players)
              p.copyWith(isAlive: p.id != 's' && p.id != 'm2'),
          ],
        ),
      ),
      VictoryStatus.mafiaWin,
    );
  });
  test(
    'independent or Mafia sniper flag does not count as citizen ability',
    () {
      for (final role in [Role.joker, Role.normalMafia]) {
        final state = parity();
        expect(
          VictoryEngine.evaluate(
            state.copyWith(
              players: [
                for (final p in state.players) p.copyWith(hasSniper: false),
                player('extra', role, sniper: true),
              ],
            ),
          ),
          VictoryStatus.mafiaWin,
          reason: role.name,
        );
      }
    },
  );
  test('spent sniper remains spent through checkpoint serialization', () {
    final state = parity().copyWith(
      eventHistory: [action(EventType.sniperKill, 's', 'm1')],
    );
    expect(
      VictoryEngine.evaluate(GameState.fromJson(state.toJson())),
      VictoryStatus.mafiaWin,
    );
  });
  test('protection exhausted on all living targets removes parity chance', () {
    final state = parity();
    final exhausted = state.copyWith(eventHistory: spentProtections(state));
    expect(VictoryEngine.evaluate(exhausted), VictoryStatus.mafiaWin);
    for (final target in state.alivePlayers) {
      expect(
        () => RuleValidator.validate(
          SubmitProtectionCommand(actorId: 'd', targetId: target.id),
          exhausted,
        ),
        throwsA(isA<ActionAlreadyUsedException>()),
      );
    }
  });
  test(
    'self protection alone is enough when all other targets are exhausted',
    () {
      final state = parity();
      final selfOnly = state.copyWith(
        eventHistory: spentProtections(
          state,
        ).where((e) => e.targetId != 'd').toList(),
      );
      expect(
        () => RuleValidator.validate(
          const SubmitProtectionCommand(actorId: 'd', targetId: 'd'),
          selfOnly,
        ),
        returnsNormally,
      );
      expect(VictoryEngine.evaluate(selfOnly), VictoryStatus.continueGame);
    },
  );
  test('any legal living protection target qualifies, including Mafia', () {
    final state = parity();
    final mafiaOnly = state.copyWith(
      eventHistory: spentProtections(
        state,
      ).where((e) => e.targetId != 'm1').toList(),
    );
    expect(
      () => RuleValidator.validate(
        const SubmitProtectionCommand(actorId: 'd', targetId: 'm1'),
        mafiaOnly,
      ),
      returnsNormally,
    );
    expect(VictoryEngine.evaluate(mafiaOnly), VictoryStatus.continueGame);
  });
  test('unused protection on a dead target does not grant parity chance', () {
    final state = parity();
    expect(
      VictoryEngine.evaluate(
        state.copyWith(
          players: [
            ...state.players,
            player('dead', Role.goodCitizen, alive: false),
          ],
          eventHistory: spentProtections(state),
        ),
      ),
      VictoryStatus.mafiaWin,
    );
  });
  test(
    'configured repeat and unlimited protection limits remain respected',
    () {
      for (final limit in [2, -1]) {
        final state = parity(protectionLimit: limit);
        expect(
          VictoryEngine.evaluate(
            state.copyWith(eventHistory: spentProtections(state)),
          ),
          VictoryStatus.continueGame,
        );
      }
    },
  );
  test('another game or another actor does not consume either ability', () {
    final state = parity();
    expect(
      VictoryEngine.evaluate(
        state.copyWith(
          eventHistory: [
            action(EventType.sniperKill, 's', 'm1', gameId: 'other'),
            action(EventType.sniperKill, 'other-sniper', 'm1'),
            for (final p in state.players)
              action(EventType.protection, 'd', p.id, gameId: 'other'),
            for (final p in state.players)
              action(EventType.protection, 'other-doctor', p.id),
          ],
        ),
      ),
      VictoryStatus.continueGame,
    );
  });
  test(
    'one citizen can hold both abilities; no distinct actor requirement',
    () {
      final state = parity().copyWith(
        players: [
          player('m1', Role.normalMafia),
          player('d', Role.citizensGirl, sniper: true),
        ],
      );
      expect(VictoryEngine.evaluate(state), VictoryStatus.continueGame);
    },
  );
  test(
    'no living Mafia means citizens win; no living citizens means Mafia win',
    () {
      final state = parity();
      expect(
        VictoryEngine.evaluate(
          state.copyWith(
            players: [player('d', Role.citizensGirl), player('j', Role.joker)],
          ),
        ),
        VictoryStatus.citizensWin,
      );
      expect(
        VictoryEngine.evaluate(
          state.copyWith(
            players: [player('m1', Role.normalMafia), player('j', Role.joker)],
          ),
        ),
        VictoryStatus.mafiaWin,
      );
    },
  );
  test(
    'Joker wins by this game voting, not an event from a different game',
    () {
      final state = parity(sniper: false).copyWith(
        players: [
          ...parity(sniper: false).players,
          player('j', Role.joker, alive: false),
        ],
      );
      for (final gameId in ['parity', 'other']) {
        expect(
          VictoryEngine.evaluate(
            state.copyWith(
              eventHistory: [
                GameEvent(
                  id: 'vote-out',
                  gameId: gameId,
                  round: 2,
                  phase: Phase.elimination,
                  type: EventType.elimination,
                  targetId: 'j',
                  timestamp: now,
                ),
              ],
            ),
          ),
          gameId == 'parity' ? VictoryStatus.jokerWin : VictoryStatus.mafiaWin,
        );
      }
    },
  );
  test('custom initial-count victory still wins without parity exception', () {
    final state = parity().copyWith(
      rules: const GameRuleset(
        victoryRules: VictoryRules(mode: VictoryMode.equalCount),
        abilityRules: AbilityRules(sniper: true),
      ),
    );
    expect(VictoryEngine.evaluate(state), VictoryStatus.mafiaWin);
  });
  test(
    'custom execution target still takes precedence over remaining abilities',
    () {
      final state = parity().copyWith(
        rules: const GameRuleset(
          victoryRules: VictoryRules(
            mode: VictoryMode.exactMafiaExecutions,
            requiredCorrectExecutions: 3,
          ),
          abilityRules: AbilityRules(sniper: true),
        ),
      );
      expect(VictoryEngine.evaluate(state), VictoryStatus.mafiaWin);
      expect(
        VictoryEngine.evaluate(state.copyWith(correctMafiaExecutionsCount: 3)),
        VictoryStatus.citizensWin,
      );
    },
  );
  test(
    'voting parity enters final night, successful shot saves citizens, next parity ends',
    () {
      final initial = parity().copyWith(
        phase: Phase.voting,
        players: [...parity().players, player('extra', Role.goodCitizen)],
      );
      final machine = GameMachine(initial, clock: () => now);
      machine.submitFinalVotes({'m1': 'extra', 's': 'extra', 'd': 'extra'});
      machine.resolveVote();
      expect(machine.state.phase, Phase.elimination);
      expect(machine.state.winner, isNull);
      machine.advanceToNight();
      expect(machine.state.phase, Phase.night);
      expect(machine.state.round, 3);
      machine.submitNightAction(
        actorId: 'm1',
        targetId: 's',
        type: EventType.assassination,
      );
      machine.submitNightAction(
        actorId: 'd',
        targetId: 's',
        type: EventType.protection,
      );
      machine.submitNightAction(
        actorId: 's',
        targetId: 'm1',
        type: EventType.sniperKill,
      );
      machine.resolveNight();
      expect(machine.state.phase, Phase.day);
      expect(machine.state.getPlayerById('m1')!.isAlive, isFalse);
      expect(machine.state.getPlayerById('s')!.isAlive, isTrue);
      machine.startVoting();
      machine.submitFinalVotes({'m2': 'd', 's': 'd'});
      machine.resolveVote();
      expect(machine.state.phase, Phase.winCheck);
      expect(machine.state.winner, Team.mafia);
      machine.advanceToNight();
      expect(machine.state.phase, Phase.winCheck);
    },
  );
  test(
    'final night with spent blocked sniper ends at parity, not another loop',
    () {
      final machine = GameMachine(parity(), clock: () => now);
      machine.submitNightAction(
        actorId: 'd',
        targetId: 'm1',
        type: EventType.protection,
      );
      machine.submitNightAction(
        actorId: 's',
        targetId: 'm1',
        type: EventType.sniperKill,
      );
      machine.resolveNight();
      expect(machine.state.alivePlayers.length, 4);
      expect(machine.state.phase, Phase.winCheck);
      expect(machine.state.winner, Team.mafia);
    },
  );
}
