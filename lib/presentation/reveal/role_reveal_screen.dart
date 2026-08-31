import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';

class RoleRevealScreen extends ConsumerStatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  ConsumerState<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends ConsumerState<RoleRevealScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isRevealed = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<Player> get _players => ref.read(gameOrchestratorProvider).players;

  void _reveal() {
    setState(() => _isRevealed = true);
    _fadeCtrl.forward();
  }

  void _hide() {
    _fadeCtrl.reverse().then((_) {
      setState(() => _isRevealed = false);
    });
  }

  void _next() {
    _fadeCtrl.reverse().then((_) {
      if (_currentIndex < _players.length - 1) {
        setState(() {
          _currentIndex++;
          _isRevealed = false;
        });
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NightScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final players = _players;
    if (players.isEmpty) {
      return const Scaffold(body: Center(child: Text('لا يوجد لاعبون')));
    }

    final player = players[_currentIndex];
    final role = player.role;
    final color = AppTheme.roleColor(role);
    final isLastPlayer = _currentIndex == players.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(players.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentIndex ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= _currentIndex ? AppTheme.mafiaPrimary : AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
              const SizedBox(height: 12),
              Text(
                'اللاعب ${_currentIndex + 1} من ${players.length}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const Spacer(flex: 2),
              // Pass phone instruction
              AnimatedOpacity(
                opacity: _isRevealed ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    const Icon(Icons.smartphone, color: AppTheme.textSecondary, size: 36),
                    const SizedBox(height: 8),
                    const Text('مرّر الهاتف إلى', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 16),
                    Text(
                      player.name,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              // Role reveal card
              FadeTransition(
                opacity: _fadeAnim,
                child: _isRevealed
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 3),
                                boxShadow: [
                                  BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  AppTheme.roleImage(role),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'أنتَ',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTheme.roleArabicName(role),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppTheme.roleAbilityDescription(role),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: role.team == Team.mafia
                                    ? AppTheme.mafiaPrimary.withValues(alpha: 0.15)
                                    : AppTheme.citizensPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role.team == Team.mafia ? '⚫ فريق المافيا' : '🔵 فريق المواطنين',
                                style: TextStyle(
                                  color: role.team == Team.mafia ? AppTheme.mafiaAccent : AppTheme.citizensAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const Spacer(flex: 2),
              // Buttons
              if (!_isRevealed)
                ElevatedButton.icon(
                  onPressed: _reveal,
                  icon: const Icon(Icons.visibility),
                  label: const Text('اكشف دوري'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mafiaPrimary),
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: _hide,
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('أخفِ الدور'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _next,
                  icon: Icon(isLastPlayer ? Icons.nights_stay : Icons.arrow_forward),
                  label: Text(isLastPlayer ? 'ابدأ الليل الأول' : 'اللاعب التالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastPlayer ? AppTheme.specialAction : AppTheme.citizensPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
