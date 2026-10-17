import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';
import 'package:mafia_nightfall/presentation/setup/role_review_screen.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';
import 'package:mafia_nightfall/presentation/reveal/role_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/voting/voting_screen.dart';
import 'package:mafia_nightfall/presentation/day/day_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'game_flow_test.dart' as f;
import 'local_endgame_test.dart' as end;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Cairo',
    )..addFont(rootBundle.load('assets/fonts/Cairo.ttf'))).load();
  });
  testWidgets(
    'rematch edits roles only; cancel restores result; start clears old routes',
    (tester) async {
      f.phone(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final completed = end.night().copyWith(
        phase: Phase.winCheck,
        winner: Team.mafia,
      );
      final results = end.MemoryResults();
      final container = end.harness(completed, results);
      addTearDown(container.dispose);
      await tester.pumpWidget(f.frame(container, const GameOverScreen()));
      await tester.pumpAndSettle();
      Future<void> rematch() async {
        await tester.tap(find.text('إعادة المباراة بنفس اللاعبين'));
        await tester.pumpAndSettle();
        expect(find.byType(SetupScreen), findsOneWidget);
        expect(find.text('قوانين وإعدادات اللعبة'), findsNothing);
        expect(find.byType(TextField), findsNothing);
      }

      await rematch();
      final nav = Navigator.of(tester.element(find.byType(SetupScreen)));
      nav.pop();
      await tester.pumpAndSettle();
      expect(container.read(gameOrchestratorProvider).id, completed.id);
      expect(container.read(gameOrchestratorProvider).winner, Team.mafia);
      await rematch();
      final labels = find.textContaining('بدء');
      expect(labels, findsWidgets);
      await tester.ensureVisible(labels.last);
      await tester.tap(labels.last);
      await tester.pumpAndSettle();
      expect(find.byType(RoleReviewScreen), findsOneWidget);
      await tester.tap(find.text('بدء اللعبة'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RoleRevealScreen), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(RoleRevealScreen))).canPop(),
        false,
      );
      final newGame = container.read(gameOrchestratorProvider);
      expect(newGame.id, isNot(completed.id));
      expect(
        newGame.players.map((p) => p.name).toSet(),
        completed.players.map((p) => p.name).toSet(),
      );
      expect(results.saved.length, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets(
    'moderator undo recreates the previous screen and kick updates its roster',
    (tester) async {
      f.phone(tester);
      final state = end
          .night(mafia: 1, citizens: 4)
          .copyWith(
            phase: Phase.day,
            discussionPaused: true,
            discussionDeadlineAt: null,
          );
      final c = end.harness(state, end.MemoryResults());
      addTearDown(c.dispose);
      final g = c.read(gameOrchestratorProvider.notifier);
      g.startVoting();
      await tester.pumpWidget(f.frame(c, const VotingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('التراجع خطوة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(find.byType(DayScreen), findsOneWidget);
      expect(c.read(gameOrchestratorProvider).phase, Phase.day);
      await tester.tap(find.byTooltip('طرد لاعب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Citizen 0').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();
      expect(
        c.read(gameOrchestratorProvider).getPlayerById('c0')!.isKicked,
        true,
      );
      expect(find.byType(DayScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'rewound night lets sniper edit or skip an already recorded shot',
    (tester) async {
      f.phone(tester);
      final state = end
          .night(mafia: 1, citizens: 4)
          .copyWith(
            rules: const GameRuleset(abilityRules: AbilityRules(sniper: true)),
            players: [
              for (final p in end.night(mafia: 1, citizens: 4).players)
                p.copyWith(hasSniper: p.id == 'c3'),
            ],
          );
      final c = end.harness(state, end.MemoryResults());
      addTearDown(c.dispose);
      final g = c.read(gameOrchestratorProvider.notifier);
      g.submitNightAction(
        actorId: 'm0',
        targetId: 'c0',
        type: EventType.assassination,
      );
      g.submitNightAction(
        actorId: 'c3',
        targetId: 'c1',
        type: EventType.sniperKill,
      );
      g.resolveNight();
      g.undoStep();
      await tester.pumpWidget(f.frame(c, const NightScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Citizen 2'));
      await tester.tap(find.text('Citizen 2'));
      await tester.pump();
      final confirm = find.text('تأكيد الإجراء');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(
        find.text('تأكيد'),
        findsOneWidget,
      ); // New target is selectable even though a shot was recorded.
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('skip-sniper')));
      await tester.tap(find.byKey(const ValueKey('skip-sniper')));
      await tester.pump(const Duration(seconds: 1));
      final after = c.read(gameOrchestratorProvider);
      expect(
        after.eventHistory.where((e) => e.type == EventType.sniperKill),
        isEmpty,
      );
      expect(after.getPlayerById('c1')!.isAlive, true);
      expect(after.getPlayerById('c0')!.isAlive, false);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets(
    'rewound protection can select the same target without consuming its limit twice',
    (tester) async {
      f.phone(tester);
      final base = end.night(mafia: 1, citizens: 4);
      final state = base.copyWith(
        rules: const GameRuleset(
          abilityRules: AbilityRules(protectionTargetLimit: 1),
        ),
        players: [
          for (final p in base.players)
            p.id == 'c3' ? p.copyWith(role: Role.citizensGirl) : p,
        ],
      );
      final c = end.harness(state, end.MemoryResults());
      addTearDown(c.dispose);
      final g = c.read(gameOrchestratorProvider.notifier);
      g.submitNightAction(
        actorId: 'm0',
        targetId: 'c0',
        type: EventType.assassination,
      );
      g.submitNightAction(
        actorId: 'c3',
        targetId: 'c1',
        type: EventType.protection,
      );
      g.resolveNight();
      g.undoStep();
      await tester.pumpWidget(f.frame(c, const NightScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Citizen 1'));
      await tester.tap(find.text('Citizen 1'));
      await tester.pump();
      await tester.ensureVisible(find.text('تأكيد الإجراء'));
      await tester.tap(find.text('تأكيد الإجراء'));
      await tester.pumpAndSettle();
      expect(find.text('تأكيد'), findsOneWidget);
      await tester.tap(find.text('تأكيد'));
      await tester.pump(const Duration(seconds: 1));
      expect(
        c
            .read(gameOrchestratorProvider)
            .eventHistory
            .where((e) => e.type == EventType.protection)
            .length,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
