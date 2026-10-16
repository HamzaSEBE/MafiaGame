import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:mafia_nightfall/main.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/presentation/day/day_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/splash/splash_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/newspaper_widget.dart';
import 'game_flow_test.dart' as fixtures;
import 'local_endgame_test.dart' as endgame;
import '../domain/night_casualties_test.dart' as news;

WidgetTester setupPhone(WidgetTester tester) {
  fixtures.phone(tester);
  return tester;
}

Future<void> backgroundAndReturn(
  WidgetTester tester,
  VoidCallback advanceClock,
) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  advanceClock();
  await tester.pump(const Duration(minutes: 1));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump(const Duration(seconds: 1));
}

ProviderContainer appContainer(GameState state, DateTime Function() clock) =>
    ProviderContainer(
      overrides: [
        gameOrchestratorProvider.overrideWith(() => fixtures.SeededGame(state)),
        gameClockProvider.overrideWithValue(clock),
        authUserProvider.overrideWith((ref) => Stream.value(null)),
        accountIdProvider.overrideWithValue(null),
        accountProfileProvider.overrideWith((ref) => Stream.value(null)),
        audioManagerProvider.overrideWithValue(fixtures.QuietAudio()),
        selectedThemeProvider.overrideWith(
          (ref) => ThemeSelectionNotifier(
            repository: fixtures.NoThemePreferences(),
            uid: 'preview',
            isPremium: true,
          ),
        ),
      ],
    );
Future<NavigatorState> boot(
  WidgetTester tester,
  ProviderContainer container,
) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MafiaNightfallApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  expect(find.byType(SplashScreen), findsNothing);
  return tester
      .widget<MaterialApp>(find.byType(MaterialApp))
      .navigatorKey!
      .currentState!;
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
    'local sniper cannot select self, can still skip or fire at a legal target',
    (tester) async {
      setupPhone(tester);
      final base = endgame.night(citizens: 2);
      final container = endgame.harness(
        base.copyWith(
          rules: const GameRuleset(abilityRules: AbilityRules(sniper: true)),
          players: [
            for (final p in base.players)
              p.id == 'c0'
                  ? p.copyWith(role: Role.citizensGirl)
                  : p.copyWith(hasSniper: p.id == 'c1'),
          ],
        ),
        endgame.MemoryResults(),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(fixtures.frame(container, const NightScreen()));
      await endgame.confirmTarget(tester, 'Citizen 1');
      await endgame.confirmTarget(tester, 'Citizen 1');
      expect(find.text('القناص'), findsWidgets);
      expect(find.text('لا يمكنك قنص نفسك'), findsOneWidget);
      final ownTile = find
          .ancestor(
            of: find.text('Citizen 1'),
            matching: find.byType(GestureDetector),
          )
          .first;
      expect(tester.widget<GestureDetector>(ownTile).onTap, isNull);
      await tester.tap(find.text('Citizen 1'));
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'تأكيد الإجراء'),
            )
            .onPressed,
        isNull,
      );
      await endgame.confirmTarget(tester, 'Mafia 0');
      await endgame.revealSummary(tester);
      expect(
        container.read(gameOrchestratorProvider).getPlayerById('m0')!.isAlive,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'newspaper shows sniper casualty without Mafia assassination title',
    (tester) async {
      setupPhone(tester);
      final container = endgame.harness(
        endgame.night(),
        endgame.MemoryResults(),
      );
      addTearDown(container.dispose);
      final state = news.resolve([news.action(EventType.sniperKill, 's', 'm')]);
      await tester.pumpWidget(
        fixtures.frame(
          container,
          Scaffold(
            body: SingleChildScrollView(
              child: NewspaperWidget(gameState: state),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ضحية القنص:'), findsOneWidget);
      expect(find.text('اغتيال المافيا:'), findsNothing);
      expect(find.text('m'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('newspaper separates simultaneous Mafia and sniper victims', (
    tester,
  ) async {
    setupPhone(tester);
    final container = endgame.harness(endgame.night(), endgame.MemoryResults());
    addTearDown(container.dispose);
    final state = news.resolve([
      news.action(EventType.assassination, 'm', 'c'),
      news.action(EventType.sniperKill, 's', 'm'),
    ]);
    await tester.pumpWidget(
      fixtures.frame(
        container,
        Scaffold(
          body: SingleChildScrollView(child: NewspaperWidget(gameState: state)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ضحية القنص:'), findsOneWidget);
    expect(find.text('اغتيال المافيا:'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'real app retains day screen and deadline through background and theme refresh',
    (tester) async {
      setupPhone(tester);
      var clock = endgame.now;
      final state = endgame
          .night(citizens: 5)
          .copyWith(
            phase: Phase.day,
            discussionDeadlineAt: clock.add(const Duration(minutes: 5)),
          );
      final container = appContainer(state, () => clock);
      addTearDown(container.dispose);
      final navigator = await boot(tester, container);
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const DayScreen()),
      );
      await tester.pumpAndSettle();
      final screenState = tester.state(find.byType(DayScreen));
      await backgroundAndReturn(
        tester,
        () => clock = clock.add(const Duration(minutes: 1)),
      );
      await container
          .read(selectedThemeProvider.notifier)
          .selectTheme('royal_gold');
      await tester.pumpAndSettle();
      expect(
        identical(tester.state(find.byType(DayScreen)), screenState),
        isTrue,
      );
      expect(find.text('04:00'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(container.read(gameOrchestratorProvider).id, state.id);
      expect(container.read(gameOrchestratorProvider).round, state.round);
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .navigatorKey!
            .currentState,
        same(navigator),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'real app keeps the selected night target when returning from background',
    (tester) async {
      setupPhone(tester);
      var clock = endgame.now;
      final container = appContainer(endgame.night(), () => clock);
      addTearDown(container.dispose);
      final navigator = await boot(tester, container);
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const NightScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Citizen 0'));
      await tester.pump();
      final screenState = tester.state(find.byType(NightScreen));
      await backgroundAndReturn(
        tester,
        () => clock = clock.add(const Duration(minutes: 1)),
      );
      await container
          .read(selectedThemeProvider.notifier)
          .selectTheme('midnight_blue');
      await tester.pumpAndSettle();
      expect(
        identical(tester.state(find.byType(NightScreen)), screenState),
        isTrue,
      );
      expect(find.byType(SplashScreen), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'تأكيد الإجراء'),
            )
            .onPressed,
        isNotNull,
      );
      expect(container.read(gameOrchestratorProvider).eventHistory, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
