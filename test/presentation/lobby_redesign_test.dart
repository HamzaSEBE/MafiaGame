import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/core/config/app_environment.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_lobby_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_join_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_player_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'game_flow_test.dart' as fixtures;
import 'qr_redesign_test.dart' as qr;
import 'auth_theme_test.dart' as images;

class LobbyService extends qr.GuestService {
  final requests = qr.ValueFeed<List<JoinRequest>>([]);
  final pending = <String, Completer<void>>{};
  final approvals = <String>[];
  final rejections = <String>[];
  bool failApproval = false, failCreation = false;
  @override
  int protocolFor(String id) => 1;
  @override
  Future<String> createSession(GameState state) async {
    if (failCreation) throw StateError('offline');
    return state.id;
  }

  @override
  Stream<List<JoinRequest>> streamJoinRequests(String id) => requests.stream;
  @override
  Future<void> approveJoinRequest(
    String id,
    String seatId,
    String player,
  ) async {
    approvals.add(player);
    if (failApproval) throw StateError('تعذر ربط هذا المقعد');
    await pending[player]?.future;
  }

  @override
  Future<void> rejectJoinRequest(String id, String player) async {
    rejections.add(player);
  }

  @override
  Future<void> close() async {
    await requests.close();
    await super.close();
  }
}

JoinRequest request(String uid, String seat) => JoinRequest(
  uid: uid,
  seatId: seat,
  displayName: uid == 'one' ? 'حمزة' : 'أحمد',
  timestamp: DateTime(2026),
);
Widget frame(LobbyService service, {GlobalKey? key, double scale = 1}) =>
    ProviderScope(
      overrides: [
        interactiveServiceProvider.overrideWithValue(service),
        gameOrchestratorProvider.overrideWith(
          () => fixtures.SeededGame(
            GameState(
              id: 'room',
              phase: Phase.roleReveal,
              players: [
                for (final seat in service.seats.value)
                  Player(
                    id: seat.id,
                    name: seat.playerName,
                    role: Role.goodCitizen,
                    createdAt: DateTime(2026),
                  ),
              ],
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: RepaintBoundary(key: key, child: child!),
          ),
        ),
        home: const JudgeLobbyScreen(),
      ),
    );
Future<void> open(
  WidgetTester tester,
  LobbyService service, {
  Size size = const Size(390, 844),
  double scale = 1,
  GlobalKey? key,
}) async {
  images.phone(tester, size);
  await tester.pumpWidget(frame(service, key: key, scale: scale));
  await tester.pumpAndSettle();
}

LobbyService serviceWithSeats() {
  final service = LobbyService();
  service.seats.update([
    qr.seat('me', 'حمزة', linked: false),
    qr.seat('a', 'أحمد', linked: false),
  ]);
  return service;
}

Future<void> tapRequest(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await qr.tapVisible(tester, finder);
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
  testWidgets('copy button writes the complete QR link including protocol', (
    tester,
  ) async {
    final service = serviceWithSeats();
    addTearDown(service.close);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final key = GlobalKey();
    await open(tester, service, key: key);
    await images.capture(tester, key, 'lobby-phone-1.2.7');
    final url = AppEnvironment.joinLink('room', protocol: 1);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      url,
    );
    await qr.tapVisible(tester, find.byKey(const ValueKey('copy-join-link')));
    expect(copied, url);
    expect(find.text('تم نسخ رابط الانضمام'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'live requests appear without expansion; independent approvals can run together',
    (tester) async {
      final service = serviceWithSeats();
      addTearDown(service.close);
      await open(tester, service);
      service.pending['one'] = Completer<void>();
      service.pending['two'] = Completer<void>();
      service.requests.update([request('one', 'me'), request('two', 'a')]);
      await tester.pumpAndSettle();
      await qr.tapVisible(tester, find.text('طلبات بانتظارك'));
      await tapRequest(tester, 'approve-one');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('approve-one')))
            .onPressed,
        isNull,
      );
      await tapRequest(tester, 'approve-two');
      expect(service.approvals, ['one', 'two']);
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const ValueKey('start-lobby-game')),
            )
            .onPressed,
        isNull,
      );
      service.pending['one']!.complete();
      service.pending['two']!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('approve-one')), findsNothing);
      expect(find.byKey(const ValueKey('approve-two')), findsNothing);
      // An acknowledgement alone does not start a game with a stale roster.
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const ValueKey('start-lobby-game')),
            )
            .onPressed,
        isNull,
      );
      service.seats.update([qr.seat('me', 'حمزة'), qr.seat('a', 'أحمد')]);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const ValueKey('start-lobby-game')),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'failed approval stays visible, can retry, and rejection has its own action',
    (tester) async {
      final service = serviceWithSeats();
      addTearDown(service.close);
      service.requests.update([request('one', 'me'), request('two', 'a')]);
      service.failApproval = true;
      await open(tester, service);
      await tapRequest(tester, 'approve-one');
      expect(find.text('تعذر ربط هذا المقعد'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('approve-one')))
            .onPressed,
        isNotNull,
      );
      service.failApproval = false;
      await tapRequest(tester, 'approve-one');
      await tapRequest(tester, 'reject-two');
      expect(service.rejections, ['two']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'creation and stream errors offer retry and keep start disabled',
    (tester) async {
      final service = serviceWithSeats();
      addTearDown(service.close);
      service.failCreation = true;
      await open(tester, service);
      expect(find.text('تعذر فتح صالة اللاعبين'), findsOneWidget);
      service.failCreation = false;
      await qr.tapVisible(tester, find.text('إعادة المحاولة'));
      service.requests.changes.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const ValueKey('start-lobby-game')),
            )
            .onPressed,
        isNull,
      );
      await qr.tapVisible(tester, find.text('إعادة المزامنة'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'large Arabic text fits 320px; desktop lobby and enlarged QR remain usable',
    (tester) async {
      final service = serviceWithSeats();
      addTearDown(service.close);
      service.requests.update([request('one', 'me')]);
      await open(tester, service, size: const Size(320, 640), scale: 1.6);
      await qr.tapVisible(tester, find.text('تكبير الرمز'));
      expect(find.byType(Dialog), findsOneWidget);
      await qr.tapVisible(tester, find.text('إغلاق'));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('approve-one')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tapRequest(tester, 'approve-one');
      expect(service.approvals, ['one']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('capture wide lobby with live requests', (tester) async {
    final service = serviceWithSeats();
    addTearDown(service.close);
    service.requests.update([request('one', 'me'), request('two', 'a')]);
    final key = GlobalKey();
    await open(tester, service, size: const Size(1100, 850), key: key);
    await images.capture(tester, key, 'lobby-wide-1.2.7');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'guest opens player immediately from membership even before roster updates',
    (tester) async {
      final service = serviceWithSeats();
      addTearDown(service.close);
      await qr.open(
        tester,
        service,
        child: const WebJoinScreen(sessionId: 'room'),
      );
      service.membership.update('me');
      await tester.pumpAndSettle();
      expect(find.byType(WebPlayerScreen), findsOneWidget);
      expect(service.seats.value.first.status, SeatStatus.unlinked);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'guest can replace pending seat choice without a second account',
    (tester) async {
      final service = serviceWithSeats();
      addTearDown(service.close);
      service.join.update(request('one', 'me'));
      await qr.open(
        tester,
        service,
        child: const WebJoinScreen(sessionId: 'room'),
      );
      await qr.tapVisible(tester, find.text('اختيار مقعد آخر'));
      await qr.tapVisible(tester, find.text('أحمد'));
      await qr.tapVisible(tester, find.text('انضمام باسم أحمد'));
      expect(service.join.value!.seatId, 'a');
      expect(find.text('مقعدك بانتظار الموافقة'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
