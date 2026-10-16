import 'package:flutter/material.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/presentation/auth/login_screen.dart';
import 'package:mafia_nightfall/presentation/auth/verify_email_screen.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(selectedThemeProvider);
    return ref
        .watch(authUserProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const Scaffold(
            body: Center(child: Text('تعذر تحميل حسابك. أعد المحاولة.')),
          ),
          data: (user) {
            if (user == null) return const LoginScreen();
            if (!user.emailVerified) return const VerifyEmailScreen();
            return const HomeScreen();
          },
        );
  }
}
