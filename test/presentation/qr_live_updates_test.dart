import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'qr_redesign_test.dart' as qr;

InteractiveSecret prompt(int revision, {bool voting = true}) =>
    InteractiveSecret(
      id: 'me',
      role: Role.goodCitizen,
      promptRevision: revision,
      requiredActions: voting
          ? [
              const PlayerActionPrompt(
                type: 'vote',
                availableTargets: ['a', 'b'],
              ),
            ]
          : [],
    );

void main() {
  for (final rootFirst in [true, false]) {
    testWidgets(
      'QR phase and secret arrive in either order (rootFirst=$rootFirst)',
      (tester) async {
        final service = qr.GuestService();
        addTearDown(service.close);
        service.rooms.update(qr.room(phase: Phase.day, revision: 10));
        service.secret.update(prompt(10, voting: false));
        await qr.open(tester, service);
        expect(find.text('الاقتراع'), findsNothing);
        void root() =>
            service.rooms.update(qr.room(phase: Phase.voting, revision: 11));
        void secret() => service.secret.update(prompt(11));
        if (rootFirst) {
          root();
        } else {
          secret();
        }
        await tester.pump();
        await tester.pump();
        expect(find.text('جارٍ تحديث المرحلة…'), findsOneWidget);
        if (rootFirst) {
          secret();
        } else {
          root();
        }
        await tester.pumpAndSettle();
        expect(find.text('جارٍ تحديث المرحلة…'), findsNothing);
        await qr.tapVisible(tester, find.text('أحمد'));
        final confirm = find.byType(ElevatedButton).last;
        expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);
      },
    );
  }
  testWidgets(
    'finished QR view receives rematch on same screen without rescanning',
    (tester) async {
      final service = qr.GuestService();
      addTearDown(service.close);
      await qr.open(tester, service);
      service.rooms.update(
        qr.room(
          phase: Phase.winCheck,
          status: SessionStatus.finished,
          revision: 5,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('دون مسح QR'), findsOneWidget);
      service.secret.update(prompt(6, voting: false));
      service.rooms.update(qr.room(phase: Phase.roleReveal, revision: 6));
      await tester.pumpAndSettle();
      expect(find.textContaining('دون مسح QR'), findsNothing);
      expect(find.textContaining('حمزة'), findsWidgets);
      expect(find.text('جارٍ تحديث المرحلة…'), findsNothing);
    },
  );
  testWidgets('kicked player loses action controls', (tester) async {
    final service = qr.GuestService();
    addTearDown(service.close);
    await qr.open(tester, service);
    service.seats.update([
      InteractiveSeat(
        id: 'me',
        playerName: 'حمزة',
        isAlive: false,
        isKicked: true,
        status: SeatStatus.linked,
        linkedUid: 'user',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('غادرت طاولة اللعب'), findsOneWidget);
    expect(find.text('أحمد'), findsNothing);
  });
  testWidgets('terminal listener error reconnects without a page reload', (
    tester,
  ) async {
    final service = qr.GuestService();
    addTearDown(service.close);
    await qr.open(tester, service);
    service.rooms.changes.addError(StateError('temporary stream failure'));
    await tester.pump();
    await tester.pump();
    service.rooms.value = qr.room(phase: Phase.voting, revision: 8);
    service.secret.value = prompt(8);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('أحمد'), findsOneWidget);
    expect(
      find.text('تعذر الاتصال بالجلسة. تحقق من الإنترنت؛ سنعيد الاتصال تلقائياً.'),
      findsNothing,
    );
  });
  testWidgets(
    'resume reattaches suspended streams and receives current voting window',
    (tester) async {
      final service = qr.GuestService();
      addTearDown(service.close);
      service.rooms.update(qr.room(phase: Phase.day, revision: 1));
      service.secret.update(prompt(1, voting: false));
      await qr.open(tester, service);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      service.rooms.value = qr.room(phase: Phase.voting, revision: 2);
      service.secret.value = prompt(2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('أحمد'), findsOneWidget);
      expect(find.text('جارٍ تحديث المرحلة…'), findsNothing);
    },
  );
}
