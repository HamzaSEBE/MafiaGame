import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/presentation/settings/settings_screen.dart';
import 'package:mafia_nightfall/presentation/premium/pricing_screen.dart';
import 'package:mafia_nightfall/presentation/setup/rule_settings_screen.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/data/repositories/theme_preferences_repository.dart';
import 'package:mafia_nightfall/presentation/day/day_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/reveal/role_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/voting/voting_screen.dart';

class QuietAudio implements AudioManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class NoThemePreferences implements ThemePreferencesRepository {
  @override
  Future<String?> load(String uid) async => null;
  @override
  Future<void> save(String uid, String themeId) async {}
}

class SeededGame extends GameOrchestrator {
  SeededGame(this.initial);
  final GameState initial;
  @override
  GameState build() => initial;
}

GameState game(Phase phase, DateTime now) => GameState(
  id: 'test-game',
  phase: phase,
  players: List.generate(
    9,
    (i) => Player(
      id: 'p$i',
      name: 'Player $i',
      role: i == 0 ? Role.normalMafia : Role.goodCitizen,
      createdAt: now,
    ),
  ),
  discussionDeadlineAt: phase == Phase.day
      ? now.add(const Duration(minutes: 5))
      : null,
);
ProviderContainer harness(GameState state, DateTime Function() clock) =>
    ProviderContainer(
      overrides: [
        gameOrchestratorProvider.overrideWith(() => SeededGame(state)),
        gameClockProvider.overrideWithValue(clock),
        audioManagerProvider.overrideWithValue(QuietAudio()),
        accountIdProvider.overrideWithValue(null),
        accountProfileProvider.overrideWith((ref) => Stream.value(null)),
        selectedThemeProvider.overrideWith(
          (ref) => ThemeSelectionNotifier(
            repository: NoThemePreferences(),
            uid: null,
            isPremium: false,
          ),
        ),
      ],
    );
Widget frame(ProviderContainer container, Widget screen) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: screen,
      ),
    );
void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'revealing all roles enters real introduction night then day with running timer',
    (tester) async {
      phone(tester);
      var now = DateTime(2026, 10, 11, 12);
      final container = harness(game(Phase.roleReveal, now), () => now);
      addTearDown(container.dispose);
      await tester.pumpWidget(frame(container, const RoleRevealScreen()));
      for (var i = 0; i < 9; i++) {
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.byIcon(Icons.fingerprint),
          findsOneWidget,
          reason: 'reveal $i',
        );
        final finger = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.fingerprint)),
        );
        await tester.pump();
        await finger.up();
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      expect(find.byType(NightScreen), findsOneWidget);
      expect(container.read(gameOrchestratorProvider).phase, Phase.night);
      await tester.tap(find.text('متابعة إلى النهار'));
      await tester.pumpAndSettle();
      expect(container.read(gameOrchestratorProvider).phase, Phase.day);
      await tester.ensureVisible(find.text('متابعة').last);
      await tester.tap(find.text('متابعة').last);
      await tester.pumpAndSettle();
      expect(find.byType(DayScreen), findsOneWidget);
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('04:57'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'discussion clock pauses, resumes, adjusts and survives reopening',
    (tester) async {
      phone(tester);
      var now = DateTime(2026, 10, 11, 12);
      final container = harness(game(Phase.day, now), () => now);
      addTearDown(container.dispose);
      await tester.pumpWidget(frame(container, const DayScreen()));
      now = now.add(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('04:55'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.pause_circle_filled));
      await tester.pump();
      now = now.add(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('04:55'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_circle_fill));
      await tester.pump();
      now = now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('04:53'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      expect(find.text('05:23'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      now = now.add(const Duration(seconds: 10));
      await tester.pumpWidget(frame(container, const DayScreen()));
      expect(find.text('05:13'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'skipping voting enters round two assassination without an introduction loop',
    (tester) async {
      phone(tester);
      final now = DateTime(2026, 10, 11, 12);
      final container = harness(game(Phase.voting, now), () => now);
      addTearDown(container.dispose);
      await tester.pumpWidget(frame(container, const VotingScreen()));
      await tester.tap(find.text('تخطي التصويت'));
      await tester.pumpAndSettle();
      final state = container.read(gameOrchestratorProvider);
      expect(state.phase, Phase.night);
      expect(state.round, 2);
      expect(find.byType(NightScreen), findsOneWidget);
      expect(find.text('الاغتيال'), findsWidgets);
      expect(find.text('متابعة إلى النهار'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'confirmed vote eliminates once and opens assassination for round two',
    (tester) async {
      phone(tester);
      final now = DateTime(2026, 10, 11, 12);
      final container = harness(game(Phase.day, now), () => now);
      addTearDown(container.dispose);
      await tester.pumpWidget(frame(container, const DayScreen()));
      await tester.ensureVisible(find.text('الانتقال للتصويت'));
      await tester.tap(find.text('الانتقال للتصويت'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نعم، انتقال'));
      await tester.pumpAndSettle();
      expect(container.read(gameOrchestratorProvider).phase, Phase.voting);
      await tester.tap(find.text('Player 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Player 1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('فرز الأصوات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ الوقت'));
      await tester.pump();
      await tester.tap(find.text('تأكيد الإعدام'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(container.read(gameOrchestratorProvider).phase, Phase.elimination);
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      final state = container.read(gameOrchestratorProvider);
      expect(state.phase, Phase.night);
      expect(state.round, 2);
      expect(state.getPlayerById('p1')!.isAlive, false);
      expect(
        state.eventHistory.where((e) => e.type == EventType.elimination).length,
        1,
      );
      expect(find.text('الاغتيال'), findsWidgets);
      expect(find.text('متابعة إلى النهار'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'upgrade opens Pricing and premium features remain in their settings',
    (tester) async {
      phone(tester);
      final now = DateTime(2026, 10, 11, 12);
      final container = harness(game(Phase.setup, now), () => now);
      addTearDown(container.dispose);
      await tester.pumpWidget(frame(container, const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('الثيمات'), findsOneWidget);
      expect(find.textContaining('Premium · ثيمات'), findsOneWidget);
      await tester.tap(find.text('Upgrade to Premium'));
      await tester.pumpAndSettle();
      expect(find.byType(PricingScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(frame(container, const RuleSettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('AI Voice Assistant'), findsOneWidget);
      expect(find.text('Premium · قريباً'), findsOneWidget);
      expect(
        tester.widget<Switch>(find.byType(Switch).first).onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'interactive back delegates exit without resetting a cancelled game',
    (tester) async {
      phone(tester);
      var exits = 0;
      final now = DateTime(2026, 10, 11, 12);
      final container = harness(game(Phase.day, now), () => now);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        frame(
          container,
          DayScreen(
            onInteractiveExit: () async {
              exits++;
            },
          ),
        ),
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exits, 1);
      expect(container.read(gameOrchestratorProvider).id, 'test-game');
      expect(container.read(gameOrchestratorProvider).phase, Phase.day);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'two full elimination and assassination cycles advance without repeats',
    () {
      var now = DateTime(2026, 10, 11, 12);
      final machine = GameMachine(
        game(Phase.roleReveal, now),
        clock: () => now,
      );
      machine.beginIntroductionNight();
      machine.resolveNight();
      for (var round = 1; round <= 2; round++) {
        expect(machine.state.phase, Phase.day);
        expect(machine.state.round, round);
        expect(
          machine.state.discussionDeadlineAt,
          now.add(const Duration(minutes: 5)),
        );
        machine.startVoting();
        machine.submitFinalVotes({
          'p0': 'p${round * 2 - 1}',
          'p8': 'p${round * 2 - 1}',
        });
        final result = machine.resolveVote();
        expect(result['eliminatedId'], 'p${round * 2 - 1}');
        expect(machine.state.phase, Phase.elimination);
        machine.advanceToNight();
        expect(machine.state.round, round + 1);
        machine.advanceToNight(); // Repeated navigation cannot increment again.
        expect(machine.state.round, round + 1);
        machine.submitNightAction(
          actorId: 'p0',
          targetId: 'p${round * 2}',
          type: EventType.assassination,
        );
        now = now.add(const Duration(minutes: 10));
        machine.resolveNight();
        expect(machine.state.getPlayerById('p${round * 2}')!.isAlive, false);
      }
      expect(machine.state.round, 3);
      expect(machine.state.phase, Phase.day);
    },
  );
}
