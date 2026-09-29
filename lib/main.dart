import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/splash/splash_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_join_screen.dart';
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
    // If Firebase fails to initialize, run an error app immediately
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

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const ProviderScope(child: MafiaNightfallApp()));
}

class MafiaNightfallApp extends StatelessWidget {
  const MafiaNightfallApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cairoTextTheme = GoogleFonts.cairoTextTheme(AppTheme.darkTheme.textTheme);

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
        home = const Scaffold(
          backgroundColor: Color(0xFF07070B),
          body: Center(
            child: Text(
              'الرجاء مسح رمز الـ QR من شاشة الحكم للانضمام للعبة.',
              style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo'),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    return MaterialApp(
      title: 'مافيا عالشوارب',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(textTheme: cairoTextTheme),
      home: home,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}