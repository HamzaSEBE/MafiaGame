import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_join_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_player_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/session_exit_confirmation.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';
import 'auth_theme_test.dart' as images;

class ValueFeed<T> {
  ValueFeed(this.value);
  T value;
  final changes = StreamController<T>.broadcast();
  Stream<T> get stream => Stream<T>.multi((c) {
    c.add(value);
    final sub = changes.stream.listen(
      c.add,
      onError: c.addError,
      onDone: c.close,
    );
    c.onCancel = sub.cancel;
  });
  void update(T next) {
    value = next;
    changes.add(next);
  }

  Future<void> close() => changes.close();
}

InteractiveSession room({
  Phase phase = Phase.voting,
  int revision = 4,
  bool open = true,
  SessionStatus status = SessionStatus.active,
  String? announcement,
}) => InteractiveSession(
  id: 'room',
  hostUid: 'host',
  status: status,
  phase: phase,
  round: 3,
  actionRevision: revision,
  actionsOpen: open,
  createdAt: DateTime(2026),
  globalAnnouncement: announcement,
);
InteractiveSeat seat(
  String id,
  String name, {
  bool linked = true,
  bool alive = true,
}) => InteractiveSeat(
  id: id,
  playerName: name,
  isAlive: alive,
  status: linked ? SeatStatus.linked : SeatStatus.unlinked,
  linkedUid: id == 'me' && linked ? 'user' : null,
);

class GuestService implements InteractiveService {
  final rooms = ValueFeed<InteractiveSession?>(room());
  final seats = ValueFeed<List<InteractiveSeat>>([
    seat('me', 'حمزة'),
    seat('a', 'أحمد'),
    seat('b', 'نور'),
  ]);
  final secret = ValueFeed<InteractiveSecret?>(
    InteractiveSecret(
      id: 'me',
      role: Role.mafiaSheikh,
      promptRevision: 4,
      mafiaTeammates: ['ليث'],
      requiredActions: [
        const PlayerActionPrompt(type: 'vote', availableTargets: ['a', 'b']),
      ],
    ),
  );
  final actions = ValueFeed<List<ActionRequest>>([]);
  final join = ValueFeed<JoinRequest?>(null);
  final membership = ValueFeed<String?>(null);
  final sent = <(String, String, int, int)>[];
  bool fail = false;
  @override
  String? get uid => 'user';
  @override
  Future<void> signInAnonymouslyIfNeeded() async {}
  @override
  Stream<InteractiveSession?> streamSession(String id) => rooms.stream;
  @override
  Stream<List<InteractiveSeat>> streamSeats(String id) => seats.stream;
  @override
  Stream<InteractiveSeat?> streamMySeat(String id, String seatId) =>
      seats.stream.map((s) => s.firstWhere((p) => p.id == seatId));
  @override
  Stream<InteractiveSecret?> streamMySecret(String id, String seatId) =>
      secret.stream;
  @override
  Stream<List<ActionRequest>> streamMyActionRequests(String id, String uid) =>
      actions.stream;
  @override
  Stream<JoinRequest?> streamMyJoinRequest(String id, String uid) =>
      join.stream;
  @override
  Stream<String?> streamMyMembership(String id, String uid) =>
      membership.stream;
  @override
  Future<void> requestSeat(String id, String seatId, String name) async {
    join.update(
      JoinRequest(
        uid: 'user',
        seatId: seatId,
        displayName: name,
        timestamp: DateTime(2026),
      ),
    );
  }

  @override
  Future<void> submitAction(
    String id,
    String seatId,
    String type,
    String target, {
    required int expectedRevision,
    int expectedActionVersion = 0,
  }) async {
    if (fail) throw StateError('offline');
    sent.add((type, target, expectedRevision, expectedActionVersion));
    actions.update([
      ActionRequest(
        id: 'user_$type',
        uid: 'user',
        seatId: seatId,
        actionType: type,
        targetId: target,
        revision: expectedRevision,
        submissionVersion: expectedActionVersion + 1,
        timestamp: DateTime(2026),
      ),
    ]);
  }

  Future<void> close() async {
    await rooms.close();
    await seats.close();
    await secret.close();
    await actions.close();
    await join.close();
    await membership.close();
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget frame(
  GuestService service,
  Widget child, {
  GlobalKey? captureKey,
  double scale = 1,
}) => ProviderScope(
  overrides: [interactiveServiceProvider.overrideWithValue(service)],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(key: captureKey, child: child!),
      ),
    ),
    home: child,
  ),
);
Future<void> open(
  WidgetTester tester,
  GuestService service, {
  Widget? child,
  GlobalKey? key,
  double scale = 1,
  Size size = const Size(390, 844),
}) async {
  images.phone(tester, size);
  await tester.pumpWidget(
    frame(
      service,
      child ?? const WebPlayerScreen(sessionId: 'room', seatId: 'me'),
      captureKey: key,
      scale: scale,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    await (FontLoader(
      'Cairo',
    )..addFont(rootBundle.load('assets/fonts/Cairo.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test(
    'all Material surfaces and containers follow each palette without generated pink',
    () {
      for (final palette in ThemeCatalog.themes) {
        final theme = AppTheme.previewTheme(palette), s = theme.colorScheme;
        expect(s.primaryContainer, palette.cardEnd);
        expect(s.surfaceContainerHigh, palette.surface);
        expect(s.primaryFixed, palette.cardStart);
        expect(s.surfaceTint, Colors.transparent);
        expect(theme.dialogTheme.backgroundColor, palette.surface);
        expect(
          theme.textButtonTheme.style!.foregroundColor!.resolve({}),
          palette.companion,
        );
      }
      expect(AppTheme.mafiaAccent, const Color(0xFF8B0000));
      expect(AppTheme.mafiaPrimary, isNot(const Color(0xFFFB7185)));
    },
  );
  testWidgets(
    'join selects a real seat, sends request and waits for judge approval',
    (tester) async {
      final service = GuestService();
      addTearDown(service.close);
      service.seats.update([
        seat('me', 'حمزة', linked: false),
        seat('a', 'أحمد', linked: false),
      ]);
      final key = GlobalKey();
      await open(
        tester,
        service,
        child: const WebJoinScreen(sessionId: 'room'),
        key: key,
      );
      await images.capture(tester, key, 'qr-join-1.2.6');
      await tapVisible(tester, find.text('أحمد'));
      await tapVisible(tester, find.text('انضمام باسم أحمد'));
      expect(find.text('مقعدك بانتظار الموافقة'), findsOneWidget);
      expect(service.join.value!.seatId, 'a');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'role and teammates stay private, reveal while held, immediately conceal and on background',
    (tester) async {
      final service = GuestService();
      addTearDown(service.close);
      final key = GlobalKey();
      await open(tester, service, key: key);
      await images.capture(tester, key, 'qr-player-1.2.6');
      expect(find.text('شيخ المافيا'), findsNothing);
      expect(find.textContaining('ليث'), findsNothing);
      var gesture = await tester.startGesture(
        tester.getCenter(find.text('هوية محمية')),
      );
      await tester.pumpAndSettle();
      expect(find.text('شيخ المافيا'), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(find.text('شيخ المافيا'), findsNothing);
      expect(find.textContaining('ليث'), findsNothing);
      gesture = await tester.startGesture(
        tester.getCenter(find.text('هوية محمية')),
      );
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('شيخ المافيا'), findsNothing);
      await gesture.up();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'voting sends current revision, changes vote using submission version, blocks closed window',
    (tester) async {
      final service = GuestService();
      addTearDown(service.close);
      await open(tester, service);
      await tapVisible(tester, find.text('أحمد'));
      await tapVisible(tester, find.text('تأكيد وإرسال'));
      expect(service.sent, [('vote', 'a', 4, 0)]);
      await tapVisible(tester, find.text('نور'));
      await tapVisible(tester, find.text('تأكيد تغيير التصويت'));
      expect(service.sent.last, ('vote', 'b', 4, 1));
      service.rooms.update(room(open: false));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'تأكيد تغيير التصويت'),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'sniper skip preserves self sentinel and completed night action cannot resend',
    (tester) async {
      final service = GuestService();
      addTearDown(service.close);
      service.rooms.update(room(phase: Phase.night));
      service.secret.update(
        InteractiveSecret(
          id: 'me',
          role: Role.goodCitizen,
          isSniper: true,
          promptRevision: 4,
          requiredActions: [
            const PlayerActionPrompt(
              type: 'sniperKill',
              availableTargets: ['me', 'a'],
            ),
          ],
        ),
      );
      await open(tester, service);
      await tapVisible(tester, find.text('تخطي القنص · احتفظ بالرصاصة'));
      expect(service.sent, [('sniperKill', 'me', 4, 0)]);
      expect(find.text('وصل قرارك'), findsOneWidget);
      expect(find.text('تخطي القنص · احتفظ بالرصاصة'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'failed action keeps selection and allows retry; stale previous vote never preselects',
    (tester) async {
      final service = GuestService();
      addTearDown(service.close);
      service.fail = true;
      service.actions.update([
        ActionRequest(
          id: 'old',
          uid: 'user',
          actionType: 'vote',
          targetId: 'a',
          revision: 3,
          timestamp: DateTime(2026),
        ),
      ]);
      await open(tester, service);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'تأكيد وإرسال'),
            )
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.text('أحمد'));
      await tapVisible(tester, find.text('تأكيد وإرسال'));
      expect(service.sent, isEmpty);
      service.fail = false;
      await tapVisible(tester, find.text('تأكيد وإرسال'));
      expect(service.sent.last.$2, 'a');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    '320 pixel large text, desktop, death and finished session remain scrollable',
    (tester) async {
      final service = GuestService();
      addTearDown(service.close);
      await open(tester, service, scale: 1.8, size: const Size(320, 640));
      await tapVisible(tester, find.text('نور'));
      await tester.ensureVisible(find.text('تأكيد وإرسال'));
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      service.seats.update([
        seat('me', 'حمزة', alive: false),
        seat('a', 'أحمد'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('انتهى دورك… وبقيت الحكاية'), findsOneWidget);
      service.rooms.update(room(status: SessionStatus.finished));
      await tester.pumpAndSettle();
      expect(find.text('انتهت اللعبة'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'public announcement fits a short landscape dialog with large text',
    (tester) async {
      final service = GuestService();
      addTearDown(service.close);
      await open(tester, service, size: const Size(640, 320), scale: 1.6);
      service.rooms.update(
        room(announcement: 'أعلن حمزة أنه شيخ المواطنين، وصوته بثلاثة أصوات.'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tapVisible(tester, find.text('حسناً'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('exit confirmation inherits original blood palette', (
    tester,
  ) async {
    final service = GuestService();
    addTearDown(service.close);
    await open(
      tester,
      service,
      child: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => confirmEndInteractiveSession(context),
            child: const Text('إنهاء'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('إنهاء'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AlertDialog>(find.byType(AlertDialog)).backgroundColor,
      ThemeCatalog.themes.first.surface,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'إنهاء الجلسة'),
          )
          .style!
          .backgroundColor!
          .resolve({}),
      const Color(0xFF8B0000),
    );
    await tester.tap(find.text('متابعة اللعبة'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
