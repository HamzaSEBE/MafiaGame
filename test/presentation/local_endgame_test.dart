import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/data/repositories/game_results_repository.dart';
import 'package:mafia_nightfall/data/repositories/history_repository.dart';
import 'package:mafia_nightfall/presentation/day/day_screen.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';
import 'package:mafia_nightfall/presentation/night/cinematic_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_summary_screen.dart';
import 'package:mafia_nightfall/presentation/voting/voting_screen.dart';
import 'game_flow_test.dart' as fixtures;

class MemoryResults extends GameResultsRepository {
  final saved = <GameState>[];
  @override
  Future<void> save(
    GameRecord record,
    GameState state, {
    bool serverOwned = false,
  }) async {
    saved.add(state);
  }
}

final now = DateTime(2026, 10, 13, 12);
GameState night({int mafia = 2, int citizens = 3, int round = 3}) => GameState(
  id: 'local-endgame',
  phase: Phase.night,
  round: round,
  initialMafiaCount: mafia,
  players: [
    for (var i = 0; i < mafia; i++)
      Player(
        id: 'm$i',
        name: 'Mafia $i',
        role: Role.normalMafia,
        createdAt: now,
      ),
    for (var i = 0; i < citizens; i++)
      Player(
        id: 'c$i',
        name: 'Citizen $i',
        role: Role.goodCitizen,
        createdAt: now,
      ),
  ],
);
ProviderContainer harness(
  GameState state,
  MemoryResults results, {
  DateTime Function()? clock,
}) => ProviderContainer(
  overrides: [
    gameOrchestratorProvider.overrideWith(() => fixtures.SeededGame(state)),
    gameClockProvider.overrideWithValue(clock ?? () => now),
    audioManagerProvider.overrideWithValue(fixtures.QuietAudio()),
    accountIdProvider.overrideWithValue(null),
    accountProfileProvider.overrideWith((ref) => Stream.value(null)),
    selectedThemeProvider.overrideWith(
      (ref) => ThemeSelectionNotifier(
        repository: fixtures.NoThemePreferences(),
        uid: null,
        isPremium: false,
      ),
    ),
    gameResultsRepositoryProvider.overrideWithValue(results),
  ],
);

Future<void> confirmTarget(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await tester.tap(find.text(name));
  await tester.pump();
  await tester.ensureVisible(find.text('تأكيد الإجراء').last);
  await tester.tap(find.text('تأكيد الإجراء').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('تأكيد'));
  await tester.pumpAndSettle();
}

Future<void> revealSummary(WidgetTester tester) async {
  expect(find.byType(CinematicRevealScreen), findsOneWidget);
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
  expect(find.byType(NightSummaryScreen), findsOneWidget);
}

Future<void> assassinate(WidgetTester tester, String name) async {
  await confirmTarget(tester, name);
  await revealSummary(tester);
}

Future<void> continueSummary(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'متابعة');
  final resultButton = find.widgetWithText(
    ElevatedButton,
    'عرض نتيجة المباراة',
  );
  final selected = resultButton.evaluate().isNotEmpty ? resultButton : button;
  await tester.ensureVisible(selected);
  await tester.tap(selected);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Cairo',
    )..addFont(rootBundle.load('assets/fonts/Cairo.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'parity with both remaining abilities continues through a real protected sniper night',
    (tester) async {
      fixtures.phone(tester);
      var clock = now;
      final results = MemoryResults();
      final base = night(citizens: 2);
      final container = harness(
        base.copyWith(
          rules: const GameRuleset(abilityRules: AbilityRules(sniper: true)),
          players: [
            for (final p in base.players)
              p.id == 'c0'
                  ? p.copyWith(role: Role.citizensGirl)
                  : p.copyWith(hasSniper: p.id == 'c1'),
          ],
        ),
        results,
        clock: () => clock,
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(fixtures.frame(container, const NightScreen()));
      await confirmTarget(tester, 'Citizen 1'); // Mafia assassination.
      expect(find.text('الحماية'), findsWidgets);
      await confirmTarget(tester, 'Citizen 1'); // Doctor saves sniper.
      expect(find.text('القناص'), findsWidgets);
      await confirmTarget(tester, 'Mafia 0');
      await revealSummary(tester);
      expect(container.read(gameOrchestratorProvider).phase, Phase.day);
      expect(container.read(gameOrchestratorProvider).winner, isNull);
      await continueSummary(tester);
      expect(find.byType(DayScreen), findsOneWidget);
      clock = clock.add(const Duration(seconds: 7));
      await tester.pump(const Duration(seconds: 7));
      expect(find.text('04:53'), findsOneWidget);
      expect(results.saved, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'voting ordinary citizen out to two versus two opens Mafia result once',
    (tester) async {
      fixtures.phone(tester);
      final results = MemoryResults();
      final container = harness(
        night().copyWith(
          phase: Phase.day,
          discussionDeadlineAt: now.add(const Duration(minutes: 5)),
        ),
        results,
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(fixtures.frame(container, const DayScreen()));
      await tester.ensureVisible(find.text('الانتقال للتصويت'));
      await tester.tap(find.text('الانتقال للتصويت'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نعم، انتقال'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mafia 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Citizen 0').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('فرز الأصوات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ الوقت'));
      await tester.pump();
      await tester.tap(find.text('تأكيد الإعدام'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(container.read(gameOrchestratorProvider).phase, Phase.winCheck);
      expect(container.read(gameOrchestratorProvider).winner, Team.mafia);
      expect(find.byType(GameOverScreen), findsOneWidget);
      expect(find.byType(NightScreen), findsNothing);
      expect(find.byType(DayScreen), findsNothing);
      expect(results.saved.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final screen in [const DayScreen(), const NightScreen()]) {
    testWidgets(
      'an ended checkpoint opened in ${screen.runtimeType} redirects once without actions',
      (tester) async {
        fixtures.phone(tester);
        final results = MemoryResults();
        final container = harness(
          night(
            citizens: 2,
          ).copyWith(phase: Phase.winCheck, winner: Team.mafia),
          results,
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(fixtures.frame(container, screen));
        await tester.pumpAndSettle();
        expect(find.byType(GameOverScreen), findsOneWidget);
        expect(find.text('فازت المافيا!'), findsOneWidget);
        expect(results.saved.length, 1);
        expect(find.text('تأكيد الإجراء'), findsNothing);
        expect(find.text('تعذر حفظ مؤقت النقاش. أعد المحاولة.'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'eliminating the Citizen Boy at parity grants retaliation, skipping it opens Mafia victory',
    (tester) async {
      fixtures.phone(tester);
      final results = MemoryResults();
      final base = night();
      final container = harness(
        base.copyWith(
          phase: Phase.voting,
          players: [
            for (final p in base.players)
              p.id == 'c0' ? p.copyWith(role: Role.citizensBoy) : p,
          ],
        ),
        results,
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(fixtures.frame(container, const VotingScreen()));
      await tester.tap(find.text('Mafia 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Citizen 0').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('فرز الأصوات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ الوقت'));
      await tester.pump();
      await tester.tap(find.text('تأكيد الإعدام'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(
        container.read(gameOrchestratorProvider).phase,
        Phase.triggeredAbility,
      );
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تخطي'));
      await tester.pumpAndSettle();
      expect(container.read(gameOrchestratorProvider).phase, Phase.winCheck);
      expect(find.byType(GameOverScreen), findsOneWidget);
      expect(find.byType(NightScreen), findsNothing);
      expect(results.saved.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'night death reaching two Mafia versus two ordinary citizens opens victory, never day',
    (tester) async {
      fixtures.phone(tester);
      final results = MemoryResults();
      final container = harness(night(), results);
      addTearDown(container.dispose);
      await tester.pumpWidget(fixtures.frame(container, const NightScreen()));
      await assassinate(tester, 'Citizen 0');
      expect(container.read(gameOrchestratorProvider).winner, Team.mafia);
      expect(container.read(gameOrchestratorProvider).phase, Phase.winCheck);
      await continueSummary(tester);
      expect(find.byType(GameOverScreen), findsOneWidget);
      expect(find.text('فازت المافيا!'), findsOneWidget);
      expect(find.byType(DayScreen), findsNothing);
      expect(find.text('تعذر حفظ مؤقت النقاش. أعد المحاولة.'), findsNothing);
      expect(results.saved.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('night elimination of the final Mafia opens citizen victory', (
    tester,
  ) async {
    fixtures.phone(tester);
    final results = MemoryResults();
    final state = night(mafia: 1, citizens: 3).copyWith(
      rules: const GameRuleset(abilityRules: AbilityRules(sniper: true)),
      players: [
        for (final p in night(mafia: 1, citizens: 3).players)
          p.copyWith(hasSniper: p.id == 'c0'),
      ],
    );
    final machine = GameMachine(state, clock: () => now);
    machine.submitNightAction(
      actorId: 'c0',
      targetId: 'm0',
      type: EventType.sniperKill,
    );
    machine.resolveNight();
    final container = harness(machine.state, results);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      fixtures.frame(container, const NightSummaryScreen()),
    );
    await tester.pumpAndSettle();
    await continueSummary(tester);
    expect(find.byType(GameOverScreen), findsOneWidget);
    expect(container.read(gameOrchestratorProvider).winner, Team.citizens);
    expect(find.byType(DayScreen), findsNothing);
    expect(results.saved.length, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'three actual night cycles keep the clock alive until parity ends the game',
    (tester) async {
      fixtures.phone(tester);
      var clock = now;
      final results = MemoryResults();
      final container = harness(
        night(citizens: 5, round: 2),
        results,
        clock: () => clock,
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(fixtures.frame(container, const NightScreen()));
      for (var i = 0; i < 3; i++) {
        await assassinate(tester, 'Citizen $i');
        await continueSummary(tester);
        if (i == 2) break;
        expect(find.byType(DayScreen), findsOneWidget);
        clock = clock.add(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('04:55'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.pause_circle_filled));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.play_circle_fill));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pump();
        expect(find.text('05:25'), findsOneWidget);
        expect(find.text('تعذر حفظ مؤقت النقاش. أعد المحاولة.'), findsNothing);
        await tester.ensureVisible(find.text('الانتقال للتصويت'));
        await tester.tap(find.text('الانتقال للتصويت'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('نعم، انتقال'));
        await tester.pumpAndSettle();
        expect(find.byType(VotingScreen), findsOneWidget);
        await tester.tap(find.text('تخطي التصويت'));
        await tester.pumpAndSettle();
        expect(container.read(gameOrchestratorProvider).phase, Phase.night);
        expect(container.read(gameOrchestratorProvider).round, i + 3);
      }
      expect(find.byType(GameOverScreen), findsOneWidget);
      expect(find.byType(DayScreen), findsNothing);
      expect(find.byType(NightScreen), findsNothing);
      expect(container.read(gameOrchestratorProvider).winner, Team.mafia);
      expect(results.saved.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
