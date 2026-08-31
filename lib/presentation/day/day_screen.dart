import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/voting/voting_screen.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameOrchestratorProvider);
    final state = ref.watch(gameOrchestratorProvider);
    final alive = state.alivePlayers;
    final dead = state.deadPlayers;
    final round = state.round;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 18),
            const SizedBox(width: 6),
            Text('النهار $round', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppTheme.error),
            tooltip: 'إنهاء اللعبة',
            onPressed: () => _confirmExit(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (round == 1)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mic, color: AppTheme.accent),
                              SizedBox(width: 8),
                              Text('تعليمات الجولة الأولى', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'أيها الحكم، اطلب من الجميع إغماض أعينهم. ثم اطلب من المافيا (فقط) فتح أعينهم ليتعرفوا على بعضهم البعض. بعد ذلك، اطلب منهم الإغماض مجدداً، ثم فليستيقظ الجميع.',
                            style: TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo', height: 1.4),
                          ),
                        ],
                      ),
                    ),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'أحياء',
                          value: '${alive.length}',
                          color: AppTheme.citizensPrimary,
                          icon: Icons.favorite,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'أموات',
                          value: '${dead.length}',
                          color: AppTheme.death,
                          icon: Icons.heart_broken,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Alive players
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('اللاعبون الأحياء (وقت التحدث: 40 ثانية)', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: alive.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = alive[i];
                        final hasBeenSilenced = state.eventHistory.any((e) => e.type == EventType.silence && e.targetId == p.id && e.round == state.round);
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.surfaceHigh.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.roleColor(p.role), width: 2),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    AppTheme.roleImage(p.role),
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        Text(AppTheme.roleArabicName(p.role), style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: AppTheme.roleColor(p.role))),
                                        if (hasBeenSilenced) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.volume_off, color: AppTheme.mafiaPrimary, size: 12),
                                          const Text(' تم إسكاته الليلة الماضية', style: TextStyle(fontSize: 10, color: AppTheme.mafiaPrimary, fontFamily: 'Cairo')),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.timer, color: AppTheme.accent),
                                onPressed: () => _showTimerDialog(context, p.name),
                                tooltip: 'بدء المؤقت (40 ثانية)',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Dead players (if any)
                  if (dead.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('الأموات', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(height: 8),
                    ...dead.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.surfaceHigh.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.death, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                p.name,
                                style: const TextStyle(color: AppTheme.death, fontSize: 15, fontFamily: 'Cairo', decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ),
                        )),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(gameOrchestratorProvider.notifier).startVoting();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VotingScreen()),
                      );
                    },
                    icon: const Icon(Icons.how_to_vote),
                    label: const Text('بدء التصويت'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning, 
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimerDialog(BuildContext context, String playerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TimerDialog(playerName: playerName),
    );
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إنهاء اللعبة؟', style: TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد أنك تريد إنهاء هذه اللعبة والعودة للقائمة الرئيسية؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameOrchestratorProvider.notifier).resetGame();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('نعم، إنهاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

class _TimerDialog extends StatefulWidget {
  final String playerName;
  const _TimerDialog({required this.playerName});

  @override
  State<_TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<_TimerDialog> {
  int _secondsLeft = 40;
  bool _isRunning = false;

  void _startTimer() async {
    setState(() => _isRunning = true);
    while (_secondsLeft > 0 && _isRunning) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRunning) return;
      setState(() => _secondsLeft--);
    }
    if (_secondsLeft == 0 && mounted) {
      setState(() => _isRunning = false);
    }
  }

  void _stopTimer() {
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _isRunning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('دور ${widget.playerName}', style: const TextStyle(fontFamily: 'Cairo'), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_secondsLeft',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _secondsLeft <= 10 ? AppTheme.error : AppTheme.success,
            ),
          ),
          const Text('ثانية متبقية', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary)),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (_secondsLeft > 0 && !_isRunning)
          ElevatedButton(
            onPressed: _startTimer,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('بدء', style: TextStyle(fontFamily: 'Cairo')),
          ),
        if (_isRunning)
          ElevatedButton(
            onPressed: _stopTimer,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('إيقاف', style: TextStyle(fontFamily: 'Cairo', color: Colors.black)),
          ),
        TextButton(
          onPressed: () {
            _isRunning = false;
            Navigator.of(context).pop();
          },
          child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
                Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );
}
