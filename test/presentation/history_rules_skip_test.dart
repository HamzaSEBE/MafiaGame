import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/data/repositories/history_repository.dart';
import 'package:mafia_nightfall/presentation/history/game_history_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/setup/rule_settings_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';
import '../application/history_repository_test.dart' as records;
import '../support/memory_firestore.dart';
import 'game_flow_test.dart' as fixtures;
import 'local_endgame_test.dart' as endgame;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Cairo',
    )..addFont(rootBundle.load('assets/fonts/Cairo.ttf'))).load();
  });
  testWidgets(
    'large history renders visible summaries only, pages, and fetches report on tap',
    (tester) async {
      fixtures.phone(tester);
      final db = MemoryFirestore(), auth = MemoryAuth('account');
      for (var i = 0; i < 5000; i++) {
        final r = records.record('g$i');
        db.documents['users/account/games/g$i'] =
            GameSummary.fromRecord(r).toJson()
              ..['date'] = DateTime(
                2026,
              ).add(Duration(minutes: i)).toIso8601String();
        db.documents['users/account/gameDetails/g$i'] = r.toJson();
      }
      final container = ProviderContainer(
        overrides: [
          historyRepositoryProvider.overrideWithValue(
            HistoryRepository(firestore: db, auth: auth),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        fixtures.frame(container, const GameHistoryScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedBackground), findsNothing);
      expect(find.byType(ListTile).evaluate().length, lessThan(12));
      expect(db.reads, ['users/account/games/*']);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(db.reads.last, 'users/account/gameDetails/g4999');
      expect(find.text('full report'), findsOneWidget);
      await tester.tap(find.text('إغلاق الجريدة'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('تحميل مباريات أقدم'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('تحميل مباريات أقدم'));
      await tester.pumpAndSettle();
      expect(db.queryLimits, [13, 13]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'history delete waits for confirmation and failed commit keeps the row',
    (tester) async {
      fixtures.phone(tester);
      final db = MemoryFirestore();
      // Use the real repository with a controllable commit, including all detail paths.
      final history = HistoryRepository(
        firestore: db,
        auth: MemoryAuth('account'),
      );
      await history.addGame(records.record('g'));
      final container = ProviderContainer(
        overrides: [historyRepositoryProvider.overrideWithValue(history)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        fixtures.frame(container, const GameHistoryScreen()),
      );
      await tester.pumpAndSettle();
      Future<void> swipe() async {
        await tester.drag(
          find.byKey(const ValueKey('g')),
          const Offset(500, 0),
        );
        await tester.pumpAndSettle();
      }

      await swipe();
      expect(find.textContaining('تبقى الإحصائيات الإجمالية'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('g')), findsOneWidget);
      db.failCommit = true;
      await swipe();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('g')), findsOneWidget);
      expect(db.documents.containsKey('users/account/gameDetails/g'), true);
      db.failCommit = false;
      await swipe();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(find.text('لا يوجد سجل بعد'), findsOneWidget);
      expect(db.documents.containsKey('users/account/gameDetails/g'), false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'classic sniper explicitly skips then fires once on a later night',
    (tester) async {
      fixtures.phone(tester);
      final base = endgame.night(citizens: 5);
      final state = base.copyWith(
        rules: const GameRuleset(abilityRules: AbilityRules(sniper: true)),
        players: [
          for (final p in base.players)
            p.id == 'c0'
                ? p.copyWith(role: Role.citizensGirl)
                : p.copyWith(hasSniper: p.id == 'c1'),
        ],
      );
      final container = endgame.harness(state, endgame.MemoryResults());
      addTearDown(container.dispose);
      await tester.pumpWidget(fixtures.frame(container, const NightScreen()));
      await endgame.confirmTarget(tester, 'Citizen 2');
      await endgame.confirmTarget(tester, 'Citizen 2');
      await tester.ensureVisible(find.byKey(const ValueKey('skip-sniper')));
      await tester.tap(find.byKey(const ValueKey('skip-sniper')));
      await tester.pumpAndSettle();
      await endgame.revealSummary(tester);
      expect(
        container
            .read(gameOrchestratorProvider)
            .eventHistory
            .where((e) => e.type == EventType.sniperKill),
        isEmpty,
      );
      await endgame.continueSummary(tester);
      await tester.ensureVisible(find.text('الانتقال للتصويت'));
      await tester.tap(find.text('الانتقال للتصويت'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نعم، انتقال'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تخطي التصويت'));
      await tester.pumpAndSettle();
      await endgame.confirmTarget(tester, 'Citizen 4');
      await endgame.confirmTarget(tester, 'Citizen 1');
      expect(find.byKey(const ValueKey('skip-sniper')), findsOneWidget);
      await endgame.confirmTarget(tester, 'Mafia 0');
      await endgame.revealSummary(tester);
      final resolved = container.read(gameOrchestratorProvider);
      expect(resolved.getPlayerById('m0')!.isAlive, false);
      expect(
        resolved.eventHistory
            .where((e) => e.type == EventType.sniperKill)
            .length,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'detailed Arabic rule descriptions fit small screens and preserve hidden rule flags',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = endgame.night().copyWith(
        phase: Phase.setup,
        rules: const GameRuleset(allowMultipleAssassinationsPerNight: true),
      );
      final container = fixtures.harness(state, () => endgame.now);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        fixtures.frame(
          container,
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: RuleSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('القناص'),
        400,
        scrollable: scroll,
      );
      expect(find.textContaining('رصاصة واحدة طوال المباراة'), findsOneWidget);
      await tester.tap(find.text('القناص'));
      await tester.pumpAndSettle();
      final save = find.text('حفظ');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        container
            .read(gameOrchestratorProvider)
            .rules
            .allowMultipleAssassinationsPerNight,
        true,
      );
      expect(
        container.read(gameOrchestratorProvider).rules.abilityRules.sniper,
        true,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
