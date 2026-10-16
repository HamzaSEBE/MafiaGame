import 'dart:async';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/services/auth_service.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  Timer? _cooldownTimer;
  bool _canResend = false;
  int _cooldown = 60;

  @override
  void initState() {
    super.initState();
    _startCheckTimer();
    _startCooldown();
  }

  void _startCheckTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkEmailVerified(),
    );
  }

  void _startCooldown() {
    setState(() {
      _canResend = false;
      _cooldown = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldown > 0) {
          _cooldown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _checkEmailVerified() async {
    final auth = ref.read(authServiceProvider);
    await auth.reloadUser();
    if (auth.isEmailVerified && mounted) {
      _timer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _resendEmail() async {
    try {
      await ref.read(authServiceProvider).resendVerificationEmail();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إرسال الرابط بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final email = ref.watch(authServiceProvider).currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: context.visual.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF5F5F7)),
            onPressed: () => ref.read(authServiceProvider).signOut(),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.visual.backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: context.visual.iconColor2,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'تم إرسال رابط التحقق إلى بريدك الإلكتروني',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF5F5F7),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    email,
                    style: TextStyle(
                      color: context.visual.iconColor2,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.visual.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _checkEmailVerified,
                    child: const Text(
                      'لقد تحققت',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _canResend ? _resendEmail : null,
                    child: Text(
                      _canResend
                          ? 'إعادة إرسال'
                          : 'إعادة إرسال بعد $_cooldown ثانية',
                      style: TextStyle(
                        color: _canResend
                            ? context.visual.iconColor2
                            : context.visual.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
