import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/splash/splash_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/web/web_join_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      if (uri.queryParameters.containsKey('session')) {
        home = WebJoinScreen(sessionId: uri.queryParameters['session']!);
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