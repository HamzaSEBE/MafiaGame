import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';
import 'package:mafia_nightfall/presentation/history/game_history_screen.dart';
import 'package:mafia_nightfall/presentation/settings/settings_screen.dart';
import 'package:mafia_nightfall/presentation/profile/profile_screen.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/data/services/auth_service.dart';
import 'dart:ui';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFF07070B), // Deep luxurious black
      body: Stack(
        children: [
          // Elegant dark background with subtle glowing gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF2A1115), // Deep dark red/mahogany core
                    Color(0xFF0F0811), // Very dark purple
                    Color(0xFF07070B), // Black edge
                  ],
                ),
              ),
            ),
          ),
          
          // Subtle noise texture overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/images/mafia_sheikh.jpg', // We can still use it faintly just for noise/texture, or omit it. Let's omit and just use pure code.
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Luxurious Header
                _buildHeader(context, ref, user),
                
                const Spacer(flex: 2),
                
                // Glowing Logo & Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface.withValues(alpha: 0.3),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.mafiaAccent.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                          border: Border.all(color: AppTheme.mafiaAccent.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.theater_comedy, // Or any elegant icon, local asset is better if we had one
                          size: 70,
                          color: AppTheme.mafiaAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'مافيا عالشوارب',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          letterSpacing: -1,
                          shadows: [
                            Shadow(color: AppTheme.mafiaAccent.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'البقاء للأذكى',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontFamily: 'Cairo',
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.play_arrow_rounded,
                        label: 'بدء لعبة جديدة',
                        primary: true,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          ref.read(gameOrchestratorProvider.notifier).resetGame();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const SetupScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 500),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.history_edu,
                        label: 'سجل المباريات',
                        primary: false,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GameHistoryScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user) {
    final displayName = user?.displayName ?? 'لاعب مجهول';
    final email = user?.email ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Settings Button
                IconButton(
                  onPressed: () {
                    ref.read(audioManagerProvider).playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  splashRadius: 24,
                ),
                const Spacer(),
                
                // Profile Info
                GestureDetector(
                  onTap: () {
                    ref.read(audioManagerProvider).playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              fontSize: 14,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontFamily: 'Cairo',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(color: AppTheme.mafiaPrimary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.mafiaPrimary.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuriousButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF4A0000)], // Mafia Red to Dark Red
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: primary ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}