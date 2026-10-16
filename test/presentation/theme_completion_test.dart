import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_nightfall/data/services/auth_service.dart';
import 'package:mafia_nightfall/presentation/auth/register_screen.dart';
import 'package:mafia_nightfall/presentation/auth/forgot_password_screen.dart';
import 'package:mafia_nightfall/presentation/auth/verify_email_screen.dart';
import 'package:mafia_nightfall/presentation/theme/theme_catalog.dart';
import 'auth_theme_test.dart' as images;

class PreviewAuth implements AuthService {
  @override
  User? get currentUser => null;
  @override
  bool get isEmailVerified => false;
  @override
  Future<void> reloadUser() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  for (final palette in ThemeCatalog.themes) {
    testWidgets(
      '${palette.id} covers complete registration recovery and verification on small screens',
      (tester) async {
        images.phone(tester, const Size(320, 640));
        for (final screen in [
          const RegisterScreen(),
          const ForgotPasswordScreen(),
          const VerifyEmailScreen(),
        ]) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [authServiceProvider.overrideWithValue(PreviewAuth())],
              child: images.frame(screen, palette, scale: 1.6),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
            palette.background,
          );
          if (screen is VerifyEmailScreen) {
            await tester.ensureVisible(find.text('لقد تحققت'));
          }
          if (screen is ForgotPasswordScreen) {
            await tester.ensureVisible(find.text('العودة لتسجيل الدخول'));
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }
  testWidgets('capture remaining original authentication screens', (
    tester,
  ) async {
    images.phone(tester, const Size(390, 844));
    for (final entry in <String, Widget>{
      'register': const RegisterScreen(),
      'password': const ForgotPasswordScreen(),
      'verification': const VerifyEmailScreen(),
    }.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(PreviewAuth())],
          child: images.frame(
            entry.value,
            ThemeCatalog.themes.first,
            captureKey: key,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await images.capture(tester, key, '${entry.key}-1.2.6');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
