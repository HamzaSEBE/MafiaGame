import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';
import 'dart:async';

class RoleRevealScreen extends ConsumerStatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  ConsumerState<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends ConsumerState<RoleRevealScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  
  // States: 0 = Lock Screen (Swipe to receive), 1 = Fingerprint Screen, 2 = Alarm Screen
  int _screenState = 0; 
  
  bool _isHolding = false;
  int _suspiciousTaps = 0;
  
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<Player> get _players => ref.read(gameOrchestratorProvider).players;
  Player get _currentPlayer => _players[_currentIndex];

  void _onSwipeComplete() {
    ref.read(audioManagerProvider).playClick();
    setState(() {
      _screenState = 1;
      _suspiciousTaps = 0;
    });
  }
  
  void _triggerAlarm() {
    ref.read(audioManagerProvider).playKill();
    setState(() => _screenState = 2);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _screenState = 0;
          _suspiciousTaps = 0;
        });
      }
    });
  }

  void _handleSuspiciousTap() {
    if (_screenState == 0) {
      _suspiciousTaps++;
      if (_suspiciousTaps >= 2) {
        _triggerAlarm();
      }
    }
  }

  void _onFingerDown(PointerDownEvent event) {
    if (_screenState == 1) {
      ref.read(audioManagerProvider).playReveal();
      setState(() => _isHolding = true);
    }
  }

  void _onFingerUp(PointerUpEvent event) {
    if (_screenState == 1 && _isHolding) {
      setState(() => _isHolding = false);
      _nextPlayer();
    }
  }

  void _nextPlayer() {
    if (_currentIndex < _players.length - 1) {
      setState(() {
        _currentIndex++;
        _screenState = 0; // Back to lock screen
        _suspiciousTaps = 0;
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NightScreen()),
      );
    }
  }

  Widget _buildLockScreen() {
    return GestureDetector(
      onTap: _handleSuspiciousTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.5,
            colors: [Color(0xFF261D15), Color(0xFF130E0A), Color(0xFF07070B)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.screen_lock_portrait, size: 80, color: Colors.white24),
            const SizedBox(height: 30),
            Text(
              'مرر الهاتف إلى',
              style: TextStyle(fontSize: 20, color: Colors.white.withValues(alpha: 0.6), fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 10),
            Text(
              _currentPlayer.name,
              style: TextStyle(
                fontSize: 42, 
                fontWeight: FontWeight.w900, 
                color: AppTheme.glowColor, 
                fontFamily: 'Cairo',
                shadows: [Shadow(color: AppTheme.glowColor, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 60),
            // Custom Swipe Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Dismissible(
                key: ValueKey('swipe_$_currentIndex'),
                direction: DismissDirection.startToEnd,
                onDismissed: (_) => _onSwipeComplete(),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.glowColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.glowColor,
                        ),
                        child: Icon(Icons.arrow_forward_ios, color: Colors.black),
                      ),
                      const Expanded(
                        child: Text(
                          'اسحب لاستلام الهاتف',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تحذير: لا تحاول كشف الدور قبل تسليم الهاتف!',
              style: TextStyle(color: AppTheme.glowColor.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'Cairo'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRevealScreen() {
    return Listener(
      onPointerDown: _onFingerDown,
      onPointerUp: _onFingerUp,
      child: Container(
        width: double.infinity,
        color: Colors.transparent, // Capture touches
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isHolding) ...[
              FadeTransition(
                opacity: _pulseCtrl,
                child: Icon(Icons.fingerprint, size: 120, color: AppTheme.glowColor),
              ),
              const SizedBox(height: 40),
              const Text(
                'اضغط باستمرار لرؤية بطاقتك',
                style: TextStyle(fontSize: 22, color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'بمجرد رفع إصبعك، سيتم قفل الشاشة.',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5), fontFamily: 'Cairo'),
              ),
            ] else ...[
              // The Card
              Container(
                width: 280,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (_currentPlayer.role.name.toLowerCase().contains('mafia')) 
                        ? [const Color(0xFF3A1515), const Color(0xFF1A0A0A)]
                        : [const Color(0xFF15223A), const Color(0xFF0A101A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.glowColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.glowColor,
                      blurRadius: 40,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.glowColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.glowColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AppTheme.roleImage(_currentPlayer.role),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentPlayer.name,
                      style: TextStyle(fontSize: 20, color: Colors.white70, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTheme.roleArabicName(_currentPlayer.role),
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppTheme.roleAbilityDescription(_currentPlayer.role),
                        style: TextStyle(fontSize: 13, color: Colors.white54, fontFamily: 'Cairo'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmScreen() {
    return Container(
      width: double.infinity,
      color: AppTheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 120, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'محاولة غش!',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 10),
          Text(
            'اللاعب السابق يحاول كشف دور ${_currentPlayer.name}!',
            style: TextStyle(fontSize: 20, color: Colors.white70, fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    return GamePopScope(
      child: Scaffold(
        
        body: Stack(
          children: [
            if (_screenState == 0) _buildLockScreen(),
            if (_screenState == 1) _buildRevealScreen(),
            if (_screenState == 2) _buildAlarmScreen(),
          ],
        ),
      ),
    );
  }
}
