import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mafia_nightfall/data/repositories/settings_repository.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load custom role names
  final settingsRepo = SettingsRepository();
  AppTheme.customRoleNames = await settingsRepo.loadCustomRoleNames();

  runApp(const ProviderScope(child: MafiaNightfallApp()));
}

class MafiaNightfallApp extends StatelessWidget {
  const MafiaNightfallApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cairoTextTheme = GoogleFonts.cairoTextTheme(AppTheme.darkTheme.textTheme);

    return MaterialApp(
      title: 'مافيا عالشوارب',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(textTheme: cairoTextTheme),
      home: const HomeScreen(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}
