import 'package:mafia_nightfall/presentation/widgets/moderator_controls.dart';
import 'package:flutter/material.dart';
import 'package:mafia_nightfall/application/interactive_prompts.dart';
import 'package:mafia_nightfall/application/theme_service.dart';
import 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/night/night_summary_screen.dart';
import 'package:mafia_nightfall/presentation/night/cinematic_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/judge_tools_sheet.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/core/error/game_error.dart';
import 'package:mafia_nightfall/presentation/widgets/completed_game_redirect.dart';

class _DynamicNightStep {
  final Player actor;
  final String arabicTitle;
  final String arabicSubtitle;
  final String arabicAction;
  final Color color;
  final EventType eventType;

  const _DynamicNightStep({
    required this.actor,
    required this.arabicTitle,
    required this.arabicSubtitle,
    required this.arabicAction,
    required this.color,
    required this.eventType,
  });
}

class NightScreen extends ConsumerStatefulWidget {
  final String? interactiveSessionId;
  final Future<void> Function()? onInteractiveExit;

  const NightScreen({
    super.key,
    this.interactiveSessionId,
    this.onInteractiveExit,
  });

  @override
  ConsumerState<NightScreen> createState() => _NightScreenState();
}

class _NightScreenState extends ConsumerState<NightScreen> {
  int _stepIndex = 0;
  String? _selectedPlayerId;
  late List<_DynamicNightStep> _activeSteps;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _buildActiveSteps();
      _initialized = true;
      Future.microtask(() => ref.read(audioManagerProvider).playClick());
    }
  }

  void _buildActiveSteps() {
    final state = ref.read(gameOrchestratorProvider);
    final alivePlayers = state.alivePlayers;
    _activeSteps = [];

    if (state.round == 1) {
      return;
    }

    final prompts = InteractivePrompts.night(
      state.copyWith(
        eventHistory: state.eventHistory
            .where((e) => !(e.round == state.round && e.phase == Phase.night))
            .toList(),
      ),
    );
    const titles = {
      'assassination': 'الاغتيال',
      'silence': 'الإسكات',
      'investigation': 'التحقيق',
      'protection': 'الحماية',
      'sniperKill': 'القناص',
    };
    const types = {
      'assassination': EventType.assassination,
      'silence': EventType.silence,
      'investigation': EventType.investigation,
      'protection': EventType.protection,
      'sniperKill': EventType.sniperKill,
    };
    for (final type in titles.keys) {
      for (final actor in alivePlayers) {
        if (prompts[actor.id]?.any((p) => p.type == type) != true) continue;
        _activeSteps.add(
          _DynamicNightStep(
            actor: actor,
            arabicTitle: titles[type]!,
            arabicSubtitle: 'بواسطة ${actor.name}',
            arabicAction: '${context.roleName(actor.role)} يفتح.. يختار.. يغمض',
            color: AppTheme.roleColor(actor.role),
            eventType: types[type]!,
          ),
        );
      }
    }
    if (_activeSteps.isNotEmpty) {
      final next = _activeSteps.indexWhere(
        (step) => !state.eventHistory.any(
          (e) =>
              e.round == state.round &&
              e.phase == Phase.night &&
              e.actorId == step.actor.id &&
              e.type == step.eventType,
        ),
      );
      _stepIndex = next < 0 ? _activeSteps.length - 1 : next;
    }
  }

  Future<void> _continueFromIntroduction() async {
    final orchestrator = ref.read(gameOrchestratorProvider.notifier);
    orchestrator.resolveNight();
    final sessionId = widget.interactiveSessionId;
    if (sessionId == null) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NightSummaryScreen()),
      );
      return;
    }

    await ref
        .read(interactiveServiceProvider)
        .syncGameState(
          sessionId,
          ref.read(gameOrchestratorProvider),
          null,
          null,
        );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NightSummaryScreen(
          interactiveSessionId: sessionId,
          onInteractiveExit: widget.onInteractiveExit,
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  bool _canSelectTarget(Player target, _DynamicNightStep step) {
    // QR uses self as a skip sentinel; local play has a separate skip button.
    if (step.eventType == EventType.sniperKill && target.id == step.actor.id) {
      return false;
    }
    final prompts = InteractivePrompts.night(
      ref.read(gameOrchestratorProvider),
    )[step.actor.id];
    return prompts?.any(
          (p) =>
              p.type == step.eventType.name &&
              p.availableTargets.contains(target.id),
        ) ??
        false;
  }

  void _confirmAction() {
    if (_selectedPlayerId == null) return;
    final targetId = _selectedPlayerId!;
    final step = _activeSteps[_stepIndex];

    showDialog(
      context: context,
      builder: (ctx) {
        final target = ref
            .read(gameOrchestratorProvider)
            .getPlayerById(targetId);
        return AlertDialog(
          backgroundColor: context.visual.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: step.color, width: 2),
          ),
          title: const Text(
            'تأكيد الإجراء',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'الإجراء',
                value: step.arabicTitle,
                color: step.color,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                label: 'بواسطة',
                value: step.actor.name,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'الهدف',
                value: target?.name ?? '؟',
                color: Colors.white,
              ),
            ],
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
              onPressed: () {
                Navigator.pop(ctx);
                try {
                  ref
                      .read(gameOrchestratorProvider.notifier)
                      .submitNightAction(
                        actorId: step.actor.id,
                        targetId: targetId,
                        type: step.eventType,
                      );

                  if (step.eventType == EventType.investigation) {
                    _showInvestigationResult(target!);
                  } else {
                    _nextStep();
                  }
                } on GameException {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تعذر تنفيذ الإجراء. أعد اختيار الهدف وحاول مرة أخرى.',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: step.color),
              child: const Text(
                'تأكيد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInvestigationResult(Player target) {
    final state = ref.read(gameOrchestratorProvider);
    final aRules = state.rules.abilityRules;

    bool isMafia = target.role.team == Team.mafia;
    bool isJoker = target.role == Role.joker;

    String resultText = 'من المواطنين';
    Color resultColor = Colors.greenAccent;
    IconData resultIcon = Icons.check_circle_outline;

    if (isMafia) {
      if (target.role == Role.mafiaSheikh) {
        if (aRules.mafiaSheikhReveal) {
          resultText = 'من المافيا!';
          resultColor = Colors.redAccent;
          resultIcon = Icons.warning_rounded;
        } else {
          // Hidden as citizen
          resultText = 'من المواطنين';
          resultColor = Colors.greenAccent;
          resultIcon = Icons.check_circle_outline;
        }
      } else {
        resultText = 'من المافيا!';
        resultColor = Colors.redAccent;
        resultIcon = Icons.warning_rounded;
      }
    } else if (isJoker && aRules.jokerReveal) {
      resultText = 'المهرج (الجوكر)!';
      resultColor = Colors.purpleAccent;
      resultIcon = Icons.theater_comedy;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.visual.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: resultColor, width: 2),
        ),
        title: const Text(
          'نتيجة التحقيق',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resultIcon, size: 64, color: resultColor),
            const SizedBox(height: 16),
            Text(
              'اللاعب ${target.name}',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resultText,
              style: TextStyle(
                color: resultColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _nextStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMafia ? Colors.redAccent : Colors.greenAccent,
            ),
            child: const Text(
              'متابعة',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_stepIndex < _activeSteps.length - 1) {
      setState(() {
        _stepIndex++;
        _selectedPlayerId = null;
      });
    } else {
      ref.read(gameOrchestratorProvider.notifier).resolveNight();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CinematicRevealScreen()),
      );
    }
  }

  void _undo() {
    if (_stepIndex > 0) {
      ref.read(gameOrchestratorProvider.notifier).undoLastNightAction();
      setState(() {
        _stepIndex--;
        _selectedPlayerId = null;
      });
    }
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
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
              'تأكيد الإنهاء',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final gameState = ref.watch(gameOrchestratorProvider);
    if (gameState.phase == Phase.winCheck) {
      return CompletedGameRedirect(
        interactiveSessionId: widget.interactiveSessionId,
      );
    }
    final round = gameState.round;

    if (_activeSteps.isEmpty) {
      if (round == 1) {
        return GamePopScope(
          onExit: widget.onInteractiveExit,
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ModeratorControls(sessionId: widget.interactiveSessionId),
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 80,
                          color: context.visual.accent,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'الليل 1 (تعارف)',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: context.visual.accent.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.volume_up_rounded,
                                  size: 48,
                                  color: context.visual.accent,
                                ),
                                onPressed: () => ref
                                    .read(audioManagerProvider)
                                    .playVoiceover('night1_intro.mp3'),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'بصوت عالي احكي:\n\nالكل يغمض عينيه\nالمافيا تفتح عينيها (للتعارف فقط)\nالمافيا تغمض\nالكل يفتح',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Cairo',
                                  height: 1.8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _continueFromIntroduction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.visual.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'متابعة إلى النهار',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              ref.read(gameOrchestratorProvider.notifier).resolveNight();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const NightSummaryScreen()),
              );
            },
            child: const Text(
              'تخطي الليل',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ),
      );
    }

    final step = _activeSteps[_stepIndex];
    final targets = gameState.alivePlayers;

    return GamePopScope(
      onExit: widget.onInteractiveExit,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'الليل $round',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
          leading: _stepIndex > 0
              ? IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white70),
                  onPressed: _undo,
                  tooltip: 'تراجع',
                )
              : null,
          actions: [
            ModeratorControls(sessionId: widget.interactiveSessionId),
            IconButton(
              icon: const Icon(Icons.handyman, color: Colors.blueAccent),
              tooltip: 'أدوات الحكم',
              onPressed: () => JudgeToolsSheet.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: step.color.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: step.color.withValues(alpha: 0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: step.color, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: step.color.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                AppTheme.roleImage(step.actor.role),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            step.arabicTitle,
                            style: TextStyle(
                              color: step.color,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            step.arabicSubtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: context.visual.surface.withValues(
                                alpha: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: step.color.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.mic, color: step.color, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    step.arabicAction,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'اختر الهدف:',
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
                              childAspectRatio: 2.2,
                            ),
                        itemCount: targets.length,
                        itemBuilder: (context, index) {
                          final player = targets[index];
                          final canSelect = _canSelectTarget(player, step);
                          final isSelected = _selectedPlayerId == player.id;

                          String errorMsg = '';
                          if (!canSelect) {
                            if (step.eventType == EventType.sniperKill &&
                                player.id == step.actor.id) {
                              errorMsg = 'لا يمكنك قنص نفسك';
                            } else if (step.eventType == EventType.silence) {
                              errorMsg = 'تم إسكاته سابقاً';
                            } else if (step.eventType == EventType.protection) {
                              errorMsg = 'تمت حمايته سابقاً';
                            } else {
                              errorMsg = 'غير متاح';
                            }
                          }

                          return GestureDetector(
                            onTap: canSelect
                                ? () {
                                    ref.read(audioManagerProvider).playClick();
                                    setState(
                                      () => _selectedPlayerId = player.id,
                                    );
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? step.color.withValues(alpha: 0.15)
                                    : (canSelect
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black45),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? step.color
                                      : (canSelect
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.transparent),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    player.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? step.color
                                          : (canSelect
                                                ? Colors.white
                                                : Colors.white24),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 16,
                                      fontFamily: 'Cairo',
                                      decoration: canSelect
                                          ? TextDecoration.none
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  if (!canSelect)
                                    Text(
                                      errorMsg,
                                      style: TextStyle(
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 10,
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (step.eventType == EventType.sniperKill)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OutlinedButton.icon(
                          key: const ValueKey('skip-sniper'),
                          onPressed: _nextStep,
                          icon: const Icon(Icons.nights_stay_outlined),
                          label: const Text(
                            'تخطي القنص · احتفظ بالرصاصة لليلة لاحقة',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _selectedPlayerId != null
                            ? _confirmAction
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: step.color,
                          disabledBackgroundColor: Colors.white10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'تأكيد الإجراء',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Colors.white,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        '$label: ',
        style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
      ),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          fontSize: 16,
        ),
      ),
    ],
  );
}
