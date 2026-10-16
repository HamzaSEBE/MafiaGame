import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/presentation/auth/auth_wrapper.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(audioManagerProvider).playSplashIntro();
    });
    _navigationTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(seconds: 1),
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final visual = context.visual;
    return Scaffold(
      backgroundColor: visual.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: visual.glowColor.withValues(
                                        alpha: .6,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color: visual.surface.withValues(
                                        alpha: .9,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: visual.accent,
                                    width: 2,
                                  ),
                                  image: const DecorationImage(
                                    image: AssetImage(
                                      'assets/images/mafia_sheikh.jpg',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              .animate(autoPlay: animate)
                              .scale(
                                duration: 1200.ms,
                                curve: Curves.easeOutBack,
                                begin: animate
                                    ? Offset.zero
                                    : const Offset(1, 1),
                              )
                              .fadeIn(duration: 800.ms, begin: animate ? 0 : 1)
                              .then(delay: 400.ms)
                              .shimmer(
                                duration: 1500.ms,
                                color: Colors.white24,
                                size: 2,
                              ),
                          const SizedBox(height: 48),
                          Text(
                                'مافيا عالشوارب',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: visual.textPrimary,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: visual.glowColor,
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              )
                              .animate(autoPlay: animate)
                              .slideY(
                                begin: animate ? 1 : 0,
                                duration: 800.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .fadeIn(duration: 800.ms, begin: animate ? 0 : 1),
                          const SizedBox(height: 16),
                          Container(
                                width: 150,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: visual.palette.actionGradient,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: visual.glowColor,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              )
                              .animate(autoPlay: animate)
                              .scaleX(
                                begin: animate ? 0 : 1,
                                alignment: Alignment.center,
                                duration: 1500.ms,
                                curve: Curves.easeInOut,
                              )
                              .then(delay: 500.ms)
                              .fade(
                                duration: 1.seconds,
                                end: animate ? 0 : 1,
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
