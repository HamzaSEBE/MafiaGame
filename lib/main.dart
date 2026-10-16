import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mafia_nightfall/core/config/app_environment.dart';
import 'dart:async';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/application/account_providers.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/application/game_recovery.dart';
import 'package:mafia_nightfall/data/repositories/checkpoints/local_checkpoint_repository.dart';
import 'package:mafia_nightfall/application/settings/role_names_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/splash/splash_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_join_screen.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:mafia_nightfall/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF07070B),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'فشل الاتصال بخادم اللعبة.\nالرجاء تحديث الصفحة والمحاولة مرة أخرى.\n\n$e',
                style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  if (AppEnvironment.useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(
      AppEnvironment.emulatorHost,
      9099,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      AppEnvironment.emulatorHost,
      8085,
    );
    await FirebaseStorage.instance.useStorageEmulator(
      AppEnvironment.emulatorHost,
      9199,
    );
  } else if (AppEnvironment.serverGames) {
    if (kIsWeb && AppEnvironment.appCheckWebSiteKey.isEmpty) {
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'هذا الإصدار يحتاج إعداد App Check لخادم الجلسات.',
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      );
      return;
    }
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
      webProvider: AppEnvironment.appCheckWebSiteKey.isEmpty
          ? null
          : ReCaptchaV3Provider(AppEnvironment.appCheckWebSiteKey),
    );
  }

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const ProviderScope(child: MafiaNightfallApp()));
}

class MafiaNightfallApp extends ConsumerStatefulWidget {
  const MafiaNightfallApp({super.key});

  @override
  ConsumerState<MafiaNightfallApp> createState() => _MafiaNightfallAppState();
}

class _MafiaNightfallAppState extends ConsumerState<MafiaNightfallApp> {
  // Theme/account refreshes and lifecycle resumes keep the same Flutter stack.
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(accountIdProvider, (previous, next) {
      if (previous != null && previous != next) {
        ref.invalidate(gameOrchestratorProvider);
        ref.invalidate(interactiveServiceProvider);
      }
    });
    ref.listen(gameOrchestratorProvider, (previous, state) {
      if (state.players.isEmpty && previous?.id != state.id) return;
      if (kIsWeb) return;
      final uid = ref.read(accountIdProvider);
      if (uid == null) return;
      unawaited(
        ref
            .read(localCheckpointRepositoryProvider)
            .save(uid, state)
            .then(
              (_) {
                ref.read(checkpointErrorProvider.notifier).state = null;
                if (state.phase == Phase.setup ||
                    state.phase == Phase.winCheck) {
                  ref.invalidate(gameRecoveryProvider);
                }
              },
              onError: (Object error) {
                ref.read(checkpointErrorProvider.notifier).state = error;
              },
            ),
      );
    });
    final themeId = ref.watch(selectedThemeProvider);
    final themeData = AppTheme.getTheme(
      themeId,
      roleNames: ref.watch(roleNamesProvider).asData?.value ?? const {},
    );

    Widget home = const SplashScreen();

    if (kIsWeb) {
      final uri = Uri.base;
      String? sessionId;

      if (uri.queryParameters.containsKey('session')) {
        sessionId = uri.queryParameters['session'];
      } else if (uri.fragment.contains('session=')) {
        final parts = uri.fragment.split('session=');
        if (parts.length > 1) {
          sessionId = parts[1].split('&').first;
        }
      }

      if (sessionId != null && sessionId.isNotEmpty) {
        home = WebJoinScreen(sessionId: sessionId);
      } else {
        home = Scaffold(
          backgroundColor: themeData.scaffoldBackgroundColor,
          body: const Center(
            child: Text(
              'الرجاء مسح رمز الـ QR من شاشة الحكم للانضمام للعبة.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'مافيا عالشوارب',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      themeAnimationDuration:
          MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero
          : const Duration(milliseconds: 200),
      themeAnimationCurve: Curves.easeOutCubic,
      home: home,
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}
