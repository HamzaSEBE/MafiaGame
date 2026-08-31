import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

class VotingScreen extends ConsumerStatefulWidget {
  const VotingScreen({super.key});

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  final Map<String, String> _votes = {}; // voterId -> candidateId

  List<Player> get _alive => ref.read(gameOrchestratorProvider).alivePlayers;

  void _showVotePicker(Player voter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceHigh, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote, color: AppTheme.warning),
                const SizedBox(width: 8),
                Text('من يختار ${voter.name}؟', style: const TextStyle(fontSize: 20, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.warning)),
              ],
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _alive.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final candidate = _alive[i];
                  final isSelected = _votes[voter.id] == candidate.id;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() => _votes[voter.id] = candidate.id);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.warning : AppTheme.surfaceHigh),
                      ),
                      child: Row(
                        children: [
                          Text(candidate.name, style: TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.warning : AppTheme.textPrimary)),
                          const Spacer(),
                          if (isSelected) const Icon(Icons.check_circle, color: AppTheme.warning),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateLocalResult() {
    if (_votes.isEmpty) {
      ref.read(gameOrchestratorProvider.notifier).skipElimination();
      _goToNight();
      return;
    }

    final voteCounts = <String, int>{};
    for (var candidateId in _votes.values) {
      voteCounts[candidateId] = (voteCounts[candidateId] ?? 0) + 1;
    }

    int maxVotes = voteCounts.values.reduce((a, b) => a > b ? a : b);
    final topCandidates = voteCounts.entries.where((e) => e.value == maxVotes).map((e) => e.key).toList();

    if (topCandidates.length > 1) {
      _showTieDialog(topCandidates);
    } else {
      _showDefenseDialog(topCandidates.first, maxVotes);
    }
  }

  void _showTieDialog(List<String> tiedIds) {
    final state = ref.read(gameOrchestratorProvider);
    final names = tiedIds.map((id) => state.getPlayerById(id)?.name ?? id).join(' و ');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.balance, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('تعادل!', style: TextStyle(color: AppTheme.warning, fontFamily: 'Cairo')),
          ],
        ),
        content: Text('تعادل بين: $names\nماذا تريد أن تفعل؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameOrchestratorProvider.notifier).skipElimination();
              _goToNight();
            },
            child: const Text('تخطّي الإقصاء', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.black),
            child: const Text('تعديل الأصوات'),
          ),
        ],
      ),
    );
  }

  void _showDefenseDialog(String accusedId, int votesCount) {
    final state = ref.read(gameOrchestratorProvider);
    final accused = state.getPlayerById(accusedId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DefenseTimerDialog(
        accused: accused,
        votesCount: votesCount,
        onConfirmElimination: () {
          ref.read(audioManagerProvider).stopMusic(); // stop heartbeat
          ref.read(audioManagerProvider).playGunshot();
          Navigator.pop(ctx);
          // 1. Submit final votes
          ref.read(gameOrchestratorProvider.notifier).submitFinalVotes(_votes);
          // 2. Resolve them
          ref.read(gameOrchestratorProvider.notifier).resolveVote();
          // 3. UI logic
          _handleElimination(accusedId);
        },
        onChangeVotes: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _handleElimination(String? eliminatedId) {
    final state = ref.read(gameOrchestratorProvider);

    if (state.phase == Phase.winCheck) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GameOverScreen()),
        (route) => false,
      );
      return;
    }

    if (eliminatedId != null) {
      final eliminated = state.getPlayerById(eliminatedId);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.roleColor(eliminated!.role), width: 2)),
          title: const Text('تم الإقصاء - الهوية الحقيقية', style: TextStyle(color: AppTheme.death, fontFamily: 'Cairo'), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.roleColor(eliminated.role), width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppTheme.roleImage(eliminated.role),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                eliminated.name,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 4),
              Text(
                'كان: ${AppTheme.roleArabicName(eliminated.role)}',
                style: TextStyle(color: AppTheme.roleColor(eliminated.role), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 8),
              const Text(
                'تم إقصاؤه من اللعبة نهائياً',
                style: TextStyle(color: AppTheme.death, fontFamily: 'Cairo'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (state.phase == Phase.triggeredAbility) {
                  _showCitizenBoyDialog(eliminatedId);
                } else {
                  _goToNight();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.roleColor(eliminated.role),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('متابعة إلى الليل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      _goToNight();
    }
  }

  void _showCitizenBoyDialog(String actorId) {
    final state = ref.read(gameOrchestratorProvider);
    final alive = state.alivePlayers;
    String? selectedId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bolt, color: AppTheme.specialAction),
              SizedBox(width: 8),
              Text('انتقام ولد المواطنين!', style: TextStyle(color: AppTheme.specialAction, fontFamily: 'Cairo')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر لاعباً ليأخذه معه كضحية:', style: TextStyle(fontFamily: 'Cairo')),
              const SizedBox(height: 12),
              ...alive.map((p) => RadioListTile<String>(
                    title: Text(p.name, style: const TextStyle(fontFamily: 'Cairo')),
                    value: p.id,
                    groupValue: selectedId,
                    activeColor: AppTheme.specialAction,
                    onChanged: (v) => setDialogState(() => selectedId = v),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _goToNight();
              },
              child: const Text('تخطّي', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: selectedId != null
                  ? () {
                      Navigator.pop(ctx);
                      final targetPlayer = state.getPlayerById(selectedId!);
                      
                      ref.read(gameOrchestratorProvider.notifier).citizenBoyRetaliation(
                            actorId: actorId,
                            targetId: selectedId!,
                            nextPhase: Phase.night,
                          );
                      
                      if (targetPlayer != null) {
                        _showRetaliationResultDialog(targetPlayer);
                      } else {
                        _routeAfterRetaliation();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.specialAction),
              child: const Text('انتقام', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _routeAfterRetaliation() {
    final newState = ref.read(gameOrchestratorProvider);
    if (newState.phase == Phase.winCheck) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GameOverScreen()),
        (route) => false,
      );
    } else {
      _goToNight();
    }
  }

  void _showRetaliationResultDialog(Player target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.roleColor(target.role), width: 2)),
        title: const Text('ضحية المواطن الشجاع!', style: TextStyle(color: AppTheme.death, fontFamily: 'Cairo'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.roleColor(target.role), width: 3),
              ),
              child: ClipOval(
                child: Image.asset(
                  AppTheme.roleImage(target.role),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(target.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Text('كان: ${AppTheme.roleArabicName(target.role)}', style: TextStyle(color: AppTheme.roleColor(target.role), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _routeAfterRetaliation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.roleColor(target.role),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('متابعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _goToNight() {
    ref.read(gameOrchestratorProvider.notifier).advanceToNight();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const NightScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final alive = _alive;
    if (alive.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final state = ref.watch(gameOrchestratorProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لوحة التصويت الشاملة', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(gameOrchestratorProvider.notifier).skipElimination();
              _goToNight();
            },
            child: const Text('تخطّي الإقصاء', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
          ),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceHigh.withValues(alpha: 0.5)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.how_to_vote, color: AppTheme.warning, size: 40),
                        SizedBox(height: 8),
                        Text('اضغط على أي لاعب لتسجيل صوته', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontFamily: 'Cairo')),
                        Text('تعديل الأصوات متاح في أي وقت', style: TextStyle(color: AppTheme.warning, fontSize: 12, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: alive.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final voter = alive[i];
                        final targetId = _votes[voter.id];
                        final target = targetId != null ? state.getPlayerById(targetId) : null;
                        
                        int votesForThisPlayer = _votes.values.where((id) => id == voter.id).length;

                        return GestureDetector(
                          onTap: () => _showVotePicker(voter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: target != null ? AppTheme.warning.withValues(alpha: 0.5) : AppTheme.surfaceHigh),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(voter.name, style: const TextStyle(fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      if (target != null)
                                        Text('يصوّت ضد: ${target.name}', style: const TextStyle(color: AppTheme.warning, fontSize: 13, fontFamily: 'Cairo'))
                                      else
                                        const Text('لم يصوت بعد', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontFamily: 'Cairo')),
                                    ],
                                  ),
                                ),
                                if (votesForThisPlayer > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text('$votesForThisPlayer', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 20, height: 1)),
                                        const Text('أصوات', style: TextStyle(color: AppTheme.error, fontSize: 10, fontFamily: 'Cairo', height: 1)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _calculateLocalResult,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('فرز الأصوات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

class _DefenseTimerDialog extends ConsumerStatefulWidget {
  final Player? accused;
  final int votesCount;
  final VoidCallback onConfirmElimination;
  final VoidCallback onChangeVotes;

  const _DefenseTimerDialog({
    required this.accused,
    required this.votesCount,
    required this.onConfirmElimination,
    required this.onChangeVotes,
  });

  @override
  ConsumerState<_DefenseTimerDialog> createState() => _DefenseTimerDialogState();
}

class _DefenseTimerDialogState extends ConsumerState<_DefenseTimerDialog> {
  int _secondsLeft = 40;
  bool _isRunning = false;

  void _startTimer() async {
    setState(() => _isRunning = true);
    // Start heartbeat
    ref.read(audioManagerProvider).playHeartbeat();
    while (_secondsLeft > 0 && _isRunning) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRunning) return;
      setState(() => _secondsLeft--);
    }
    if (_secondsLeft == 0 && mounted) {
      setState(() => _isRunning = false);
      ref.read(audioManagerProvider).stopMusic();
    }
  }

  @override
  void dispose() {
    _isRunning = false;
    ref.read(audioManagerProvider).stopMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.error, width: 2)),
      title: const Text('مرحلة التبرير!', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.accused?.name ?? '—',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 4),
          Text(
            'حصل على أعلى الأصوات (${widget.votesCount} صوت)',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 24),
          Text(
            '$_secondsLeft',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _secondsLeft <= 10 ? AppTheme.error : AppTheme.success,
            ),
          ),
          const Text('ثانية متبقية للدفاع عن نفسه', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary)),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        if (_secondsLeft > 0 && !_isRunning)
          ElevatedButton(
            onPressed: _startTimer,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(double.infinity, 48)),
            child: const Text('بدء المؤقت', style: TextStyle(fontFamily: 'Cairo')),
          ),
        const SizedBox(height: 12),
        const Text('بعد انتهاء التبرير، اسأل الجميع:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onChangeVotes,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.warning),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('تغيير الأصوات', style: TextStyle(color: AppTheme.warning, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onConfirmElimination,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('تأكيد الإقصاء', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
