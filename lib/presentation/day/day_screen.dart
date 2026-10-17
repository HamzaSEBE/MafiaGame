import 'package:mafia_nightfall/presentation/widgets/moderator_controls.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/presentation/widgets/game_round_header.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/presentation/voting/voting_screen.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';
import 'dart:async';
import 'package:mafia_nightfall/presentation/widgets/judge_tools_sheet.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/completed_game_redirect.dart';

class DayScreen extends ConsumerStatefulWidget {
  final String? interactiveSessionId;
  final Future<void> Function()? onInteractiveStartVoting;
  final Future<void> Function()? onInteractiveExit;

  const DayScreen({
    super.key,
    this.interactiveSessionId,
    this.onInteractiveStartVoting,
    this.onInteractiveExit,
  });

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  int _timeLeft = 300; // 5 minutes
  Timer? _timer;
  bool _isPaused = false;
  bool _clockBusy = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(gameOrchestratorProvider);
    if (saved.phase != Phase.day) return;
    _isPaused = saved.discussionPaused;
    _timeLeft = saved.discussionDeadlineAt == null
        ? saved.discussionRemainingSeconds
        : math.max(
            0,
            saved.discussionDeadlineAt!
                .difference(ref.read(gameClockProvider)())
                .inSeconds,
          );
    if (saved.discussionDeadlineAt == null && !saved.discussionPaused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyClock(_timeLeft, false);
      });
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final saved = ref.read(gameOrchestratorProvider);
      if (saved.phase != Phase.day) return;
      setState(() {
        _isPaused = saved.discussionPaused;
        _timeLeft = saved.discussionDeadlineAt == null
            ? saved.discussionRemainingSeconds
            : math.max(
                0,
                saved.discussionDeadlineAt!
                    .difference(ref.read(gameClockProvider)())
                    .inSeconds,
              );
      });
    });
  }

  Future<void> _applyClock(int seconds, bool paused) async {
    if (_clockBusy) return;
    final before = ref.read(gameOrchestratorProvider);
    if (before.phase != Phase.day) return;
    setState(() => _clockBusy = true);
    try {
      ref
          .read(gameOrchestratorProvider.notifier)
          .updateDiscussionClock(seconds, paused: paused);
      final id = widget.interactiveSessionId;
      if (id != null) {
        await ref
            .read(interactiveServiceProvider)
            .setDiscussionClock(id, seconds, paused: paused);
      }
      if (mounted) {
        setState(() {
          _timeLeft = seconds;
          _isPaused = paused;
        });
      }
    } catch (_) {
      ref.read(gameOrchestratorProvider.notifier).restoreCheckpoint(before);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ مؤقت النقاش. أعد المحاولة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _clockBusy = false);
    }
  }

  void _togglePause() => _applyClock(_timeLeft, !_isPaused);
  void _adjustTime(int seconds) =>
      _applyClock((_timeLeft + seconds).clamp(0, 7200), _isPaused);

  String get _formattedTime {
    final m = (_timeLeft / 60).floor().toString().padLeft(2, '0');
    final s = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    if (widget.onInteractiveExit != null) {
      widget.onInteractiveExit!();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.visual.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'إنهاء اللعبة؟',
          style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(gameOrchestratorProvider.notifier).endGame();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.visual.accent,
            ),
            child: const Text(
              'نعم، إنهاء',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final state = ref.watch(gameOrchestratorProvider);
    if (state.phase == Phase.winCheck) {
      _timer?.cancel();
      return CompletedGameRedirect(
        interactiveSessionId: widget.interactiveSessionId,
      );
    }

    // Listen for Citizen Sheikh reveal event to show it to all clients/moderator
    ref.listen(gameOrchestratorProvider, (previous, next) {
      if (previous == null) return;
      final prevEvents = previous.eventHistory.length;
      final nextEvents = next.eventHistory.length;
      if (nextEvents > prevEvents) {
        final newEvent = next.eventHistory.last;
        if (newEvent.type == EventType.citizenSheikhReveal) {
          final sheikh = next.getPlayerById(newEvent.actorId!);
          if (sheikh != null) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: context.visual.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: context.visual.accent, width: 2),
                ),
                title: Column(
                  children: [
                    Icon(
                      Icons.campaign,
                      color: context.visual.accent,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'إفصاح شيخ المواطنين!',
                      style: TextStyle(
                        color: context.visual.accent,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'اللاعب: ${sheikh.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          AppTheme.roleImage(Role.citizensSheikh),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'كشف عن نفسه كشيخ للمواطنين!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.visual.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'أصبح صوته الآن يعادل 3 أصوات!',
                        style: TextStyle(
                          color: context.visual.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.visual.accent,
                      ),
                      child: const Text(
                        'حسناً',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }
    });
    final alive = state.alivePlayers;
    final dead = state.deadPlayers;
    final round = state.round;

    return GamePopScope(
      onExit: widget.onInteractiveExit,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: GameRoundHeader(round: round),
          actions: [
            ModeratorControls(
              sessionId: widget.interactiveSessionId,
              enabled: !_clockBusy,
            ),
            IconButton(
              icon: const Icon(Icons.handyman, color: Colors.blueAccent),
              tooltip: 'أدوات الحكم',
              onPressed: () => JudgeToolsSheet.show(context),
            ),
            if (state.rules.abilityRules.citizenSheikhReveal &&
                widget.interactiveSessionId == null)
              IconButton(
                icon: Icon(Icons.campaign, color: context.visual.accent),
                tooltip: 'إفصاح شيخ المواطنين',
                onPressed: () {
                  final sheikh = state.alivePlayers
                      .where(
                        (p) =>
                            p.role == Role.citizensSheikh &&
                            !p.isCitizenSheikhRevealed,
                      )
                      .firstOrNull;
                  if (sheikh == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'لا يمكن الكشف: شيخ المواطنين ميت أو كشف عن نفسه مسبقاً',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: context.visual.accent,
                      ),
                    );
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: context.visual.surface,
                      title: const Text(
                        'إفصاح شيخ المواطنين',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      content: Text(
                        'هل أنت متأكد من أن ${sheikh.name} يريد الكشف عن هويته؟ سيصبح صوته بـ 3 أصوات لآخر اللعبة.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              color: Colors.white54,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref
                                .read(gameOrchestratorProvider.notifier)
                                .citizenSheikhReveal(sheikh.id);
                          },
                          child: Text(
                            'تأكيد الكشف',
                            style: TextStyle(
                              color: context.visual.accent,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              tooltip: 'إنهاء اللعبة',
              onPressed: () => _confirmExit(context, ref),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: context.visual.backgroundGradient,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Timer Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: context.visual.accent.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.visual.accent.withValues(alpha: 0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'وقت النقاش المتبقي',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formattedTime,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Courier',
                              color: _timeLeft < 60
                                  ? Colors.redAccent
                                  : context.visual.accent,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.white54,
                                ),
                                onPressed: () => _adjustTime(-30),
                                tooltip: 'إنقاص 30 ثانية',
                              ),
                              IconButton(
                                icon: Icon(
                                  _isPaused
                                      ? Icons.play_circle_fill
                                      : Icons.pause_circle_filled,
                                  color: context.visual.accent,
                                  size: 40,
                                ),
                                onPressed: _togglePause,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white54,
                                ),
                                onPressed: () => _adjustTime(30),
                                tooltip: 'زيادة 30 ثانية',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'تحدثوا وتشاوروا لمعرفة القاتل!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'الأحياء (يحق لهم النقاش):',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.8,
                            ),
                        itemCount: alive.length,
                        itemBuilder: (context, index) {
                          final player = alive[index];
                          final isSilenced = state.eventHistory.any(
                            (e) =>
                                e.type == EventType.silence &&
                                e.targetId == player.id &&
                                e.round == round,
                          );
                          return Container(
                            decoration: BoxDecoration(
                              color: isSilenced
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSilenced
                                    ? Colors.redAccent.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    color: isSilenced
                                        ? Colors.redAccent
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                // Role badge is hidden during the day. Only shown in Judge Tools.
                                if (isSilenced)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text(
                                      '🔇 تم إسكاته',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 10,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (dead.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الأموات (لا يحق لهم الكلام):',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: dead.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                dead[index].name,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  decoration: TextDecoration.lineThrough,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: context.visual.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                'إنهاء النقاش؟',
                                style: TextStyle(
                                  color: context.visual.accent,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                'هل أنت متأكد من إنهاء وقت النقاش والانتقال لمرحلة التصويت؟',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    'إلغاء',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.visual.accent,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    if (widget.onInteractiveStartVoting !=
                                        null) {
                                      widget.onInteractiveStartVoting!().then((
                                        _,
                                      ) {
                                        if (context.mounted) {
                                          if (widget.interactiveSessionId !=
                                                  null &&
                                              ref
                                                      .read(
                                                        gameOrchestratorProvider,
                                                      )
                                                      .phase ==
                                                  Phase.winCheck) {
                                            Navigator.of(
                                              context,
                                            ).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (_) => GameOverScreen(
                                                  interactiveSessionId: widget
                                                      .interactiveSessionId,
                                                ),
                                              ),
                                            );
                                          } else {
                                            Navigator.of(context).pop();
                                          }
                                        }
                                      });
                                    } else {
                                      ref
                                          .read(
                                            gameOrchestratorProvider.notifier,
                                          )
                                          .startVoting();
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => const VotingScreen(),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'نعم، انتقال',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.visual.accent,
                          elevation: 10,
                          shadowColor: context.visual.accent.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'الانتقال للتصويت',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
