import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mafia_nightfall/presentation/auth/auth_wrapper.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioManagerProvider).playSplashIntro();
    });

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (_, __, ___) => const AuthWrapper(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712), // Deep, cinematic black
      body: Stack(
        children: [
          // Subtle particle/glow effect in background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.mafiaPrimary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  radius: 1.5,
                  center: Alignment.center,
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fadeIn(duration: 2.seconds).then().fadeOut(duration: 2.seconds),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Logo Animation
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.mafiaPrimary.withValues(alpha: 0.6),
                        blurRadius: 60,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: AppTheme.surface.withValues(alpha: 0.9),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: AppTheme.mafiaPrimary, width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/mafia_sheikh.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                .scale(duration: 1200.ms, curve: Curves.easeOutBack, begin: const Offset(0.0, 0.0))
                .fadeIn(duration: 800.ms)
                .then(delay: 400.ms)
                .shimmer(duration: 1500.ms, color: Colors.white24, size: 2),

                const SizedBox(height: 48),

                // Title animation
                Text(
                  'مافيا عالشوارب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: AppTheme.mafiaPrimary, blurRadius: 20, offset: Offset(0, 4)),
                    ],
                  ),
                )
                .animate()
                .slideY(begin: 1, duration: 800.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 800.ms),

                const SizedBox(height: 16),
                
                // Subtitle / loading indicator
                Container(
                  width: 150,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.mafiaPrimary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: AppTheme.mafiaPrimary, blurRadius: 10),
                    ],
                  ),
                )
                .animate()
                .scaleX(begin: 0, alignment: Alignment.center, duration: 1500.ms, curve: Curves.easeInOut)
                .then(delay: 500.ms)
                .fadeOut(duration: 1.seconds),
              ],
            ),
          ),
        ],
      ),
    );
  }
}