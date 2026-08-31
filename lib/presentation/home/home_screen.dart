import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';
import 'package:mafia_nightfall/presentation/history/game_history_screen.dart';
import 'package:mafia_nightfall/presentation/settings/settings_screen.dart';
import 'package:mafia_nightfall/presentation/stats/stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Epic Logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background glow for the logo
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.mafiaPrimary.withValues(alpha: 0.2),
                                blurRadius: 80,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'مافيا',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 64,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo',
                                    shadows: [
                                      Shadow(
                                        color: AppTheme.mafiaPrimary,
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                            ),
                            Text(
                              'عالشوارب',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: AppTheme.citizensPrimary.withValues(alpha: 0.9),
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cairo',
                                    fontSize: 32,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      width: 150,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          AppTheme.mafiaPrimary,
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'مساعد حكم لعبة المافيا',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Glassmorphism Buttons
                    _EpicButton(
                      label: 'بدء لعبة جديدة',
                      icon: Icons.play_arrow_rounded,
                      color: AppTheme.mafiaPrimary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SetupScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EpicButton(
                      label: 'سجل الألعاب',
                      icon: Icons.history_rounded,
                      color: AppTheme.citizensPrimary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameHistoryScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EpicButton(
                      label: 'تخصيص الأدوار',
                      icon: Icons.settings_rounded,
                      color: Colors.white70,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EpicButton(
                      label: 'إحصائيات اللاعبين',
                      icon: Icons.leaderboard_rounded,
                      color: Colors.amber,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      ),
                    ),
                    const Spacer(),
                    // Footer version or text
                    const Text(
                      'V 1.0.0 - EPIC EDITION',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpicButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EpicButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            highlightColor: color.withValues(alpha: 0.2),
            splashColor: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.7), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
