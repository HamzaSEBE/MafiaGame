import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/night/night_summary_screen.dart';
import 'package:mafia_nightfall/presentation/night/cinematic_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/judge_tools_sheet.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';

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

    // 1. Assassination Step (Mafia Hierarchy)
    final sheikh =
        alivePlayers.where((p) => p.role == Role.mafiaSheikh).firstOrNull;
    final girl =
        alivePlayers.where((p) => p.role == Role.mafiaGirl).firstOrNull;
    final normal =
        alivePlayers.where((p) => p.role == Role.normalMafia).firstOrNull;

    Player? assassinationActor = sheikh ?? girl ?? normal;

    if (assassinationActor != null) {
      String title = 'الاغتيال';
      String subtitle = assassinationActor.role == Role.mafiaSheikh
          ? 'بواسطة شيخ المافيا'
          : (assassinationActor.role == Role.mafiaGirl
              ? 'بواسطة بنت المافيا (الغدارة)'
              : 'بواسطة المافيا العادية (الغدارة)');

      String prompt = assassinationActor.role == Role.mafiaSheikh
          ? 'بصوت عالي: "شيخ المافيا يفتح.. شيخ المافيا يغتال.. شيخ المافيا يغمض"'
          : (assassinationActor.role == Role.mafiaGirl
              ? 'بصوت عالي: "بنت المافيا تفتح.. بنت المافيا تغتال.. بنت المافيا تغمض"'
              : 'بصوت عالي: "المافيا تفتح.. المافيا تغتال.. المافيا تغمض"');

      _activeSteps.add(_DynamicNightStep(
        actor: assassinationActor,
        arabicTitle: title,
        arabicSubtitle: subtitle,
        arabicAction: prompt,
        color: Colors.redAccent,
        eventType: EventType.assassination,
      ));
    }

    // 2. Silence Step (Mafia Girl)
    if (girl != null) {
      _activeSteps.add(_DynamicNightStep(
        actor: girl,
        arabicTitle: 'الإسكات',
        arabicSubtitle: 'بواسطة بنت المافيا',
        arabicAction:
            'بصوت عالي: "بنت المافيا تفتح.. بنت المافيا تسكت.. بنت المافيا تغمض"',
        color: Colors.blueAccent,
        eventType: EventType.silence,
      ));
    }

    // 3. Investigation Step (Citizen Sheikh)
    final citizenSheikh =
        alivePlayers.where((p) => p.role == Role.citizensSheikh).firstOrNull;
    if (citizenSheikh != null) {
      _activeSteps.add(_DynamicNightStep(
        actor: citizenSheikh,
        arabicTitle: 'التحقيق',
        arabicSubtitle: 'بواسطة شيخ المواطنين',
        arabicAction:
            'بصوت عالي: "شيخ المواطنين يفتح.. شيخ المواطنين يحقق.. شيخ المواطنين يغمض"',
        color: Colors.orangeAccent,
        eventType: EventType.investigation,
      ));
    }

    // 4. Protection Step (Citizen Girl)
    final citizenGirl =
        alivePlayers.where((p) => p.role == Role.citizensGirl).firstOrNull;
    if (citizenGirl != null) {
      _activeSteps.add(_DynamicNightStep(
        actor: citizenGirl,
        arabicTitle: 'الحماية',
        arabicSubtitle: 'بواسطة بنت المواطنين',
        arabicAction:
            'بصوت عالي: "بنت المواطنين تفتح.. بنت المواطنين تحمي.. بنت المواطنين تغمض"',
        color: Colors.greenAccent,
        eventType: EventType.protection,
      ));
    }

    // 5. Sniper Step
    if (state.rules.abilityRules.sniper) {
      final sniper = alivePlayers.where((p) => p.hasSniper).firstOrNull;
      if (sniper != null) {
        final hasShot = state.eventHistory.any((e) => e.type == EventType.sniperKill);
        if (!hasShot) {
          _activeSteps.add(_DynamicNightStep(
            actor: sniper,
            arabicTitle: 'القناص',
            arabicSubtitle: 'بواسطة المواطن القناص',
            arabicAction:
                'بصوت عالي: "القناص يفتح.. هل تريد القنص الليلة؟ اختر هدفك أو تخطى.. القناص يغمض"',
            color: Colors.amberAccent,
            eventType: EventType.sniperKill,
          ));
        }
      }
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

    await ref.read(interactiveServiceProvider).syncGameState(
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
    final state = ref.read(gameOrchestratorProvider);

    if (step.eventType == EventType.assassination) {
      if (target.id == step.actor.id) return false;
      if (target.role.team == Team.mafia) return false;
    }

    final pLimit = state.rules.abilityRules.protectionTargetLimit;
    final sLimit = state.rules.abilityRules.silenceTargetLimit;

    if (step.eventType == EventType.silence) {
      final pastSilences = state.eventHistory.where((e) =>
          e.type == EventType.silence &&
          e.actorId == step.actor.id &&
          e.targetId == target.id);
      if (sLimit != -1 && pastSilences.length >= sLimit) return false;
    }

    if (step.eventType == EventType.protection) {
      final pastProtections = state.eventHistory.where((e) =>
          e.type == EventType.protection &&
          e.actorId == step.actor.id &&
          e.targetId == target.id);
      if (pLimit != -1 && pastProtections.length >= pLimit) return false;
    }

    if (step.eventType == EventType.investigation) {
      if (target.id == step.actor.id) return false;
    }
    
    if (step.eventType == EventType.sniperKill) {
      if (target.id == step.actor.id) return false;
    }

    return true;
  }

  void _confirmAction() {
    if (_selectedPlayerId == null) return;
    final step = _activeSteps[_stepIndex];

    showDialog(
      context: context,
      builder: (ctx) {
        final target = ref
            .read(gameOrchestratorProvider)
            .getPlayerById(_selectedPlayerId!);
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: step.color, width: 2)),
          title: const Text('تأكيد الإجراء',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                  label: 'الإجراء', value: step.arabicTitle, color: step.color),
              const SizedBox(height: 4),
              _InfoRow(
                  label: 'بواسطة',
                  value: step.actor.name,
                  color: Colors.white70),
              const SizedBox(height: 12),
              _InfoRow(
                  label: 'الهدف',
                  value: target?.name ?? '؟',
                  color: Colors.white),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(gameOrchestratorProvider.notifier).submitNightAction(
                      actorId: step.actor.id,
                      targetId: _selectedPlayerId!,
                      type: step.eventType,
                    );

                if (step.eventType == EventType.investigation) {
                  _showInvestigationResult(target!);
                } else {
                  _nextStep();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: step.color),
              child: const Text('تأكيد',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: resultColor,
                width: 2)),
        title: const Text('نتيجة التحقيق',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resultIcon,
                size: 64,
                color: resultColor),
            const SizedBox(height: 16),
            Text('اللاعب ${target.name}',
                style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
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
                backgroundColor:
                    isMafia ? Colors.redAccent : Colors.greenAccent),
            child: const Text('متابعة',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold)),
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
          MaterialPageRoute(builder: (_) => const CinematicRevealScreen()));
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
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إنهاء اللعبة؟',
            style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo')),
        content: const Text(
            'هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد الإنهاء',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    final gameState = ref.watch(gameOrchestratorProvider);
    final round = gameState.round;

    if (_activeSteps.isEmpty) {
      if (round == 1) {
        return GamePopScope(
          onExit: widget.onInteractiveExit,
          child: Scaffold(
            
            body: Stack(
              children: [
                Positioned.fill(
                    child: Container(
                        decoration: const BoxDecoration(
                            gradient: RadialGradient(
                                center: Alignment.topCenter,
                                radius: 1.5,
                                colors: [
                      Color(0xFF261D15),
                      Color(0xFF130E0A),
                      Color(0xFF07070B)
                    ])))),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.nightlight_round,
                            size: 80, color: Colors.orangeAccent),
                        const SizedBox(height: 24),
                        Text('الليل 1 (تعارف)',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo')),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded,
                                    size: 48, color: Colors.orangeAccent),
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
                                    fontWeight: FontWeight.bold),
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
                              backgroundColor: Colors.orangeAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('متابعة إلى النهار',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'Cairo')),
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
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const NightSummaryScreen()));
            },
            child:
                const Text('تخطي الليل', style: TextStyle(fontFamily: 'Cairo')),
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
          title: Text('الليل $round',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo')),
          leading: _stepIndex > 0
              ? IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white70),
                  onPressed: _undo,
                  tooltip: 'تراجع',
                )
              : null,
          actions: [
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
                    decoration: const BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: 1.5,
                            colors: [
                  Color(0xFF261D15),
                  Color(0xFF130E0A),
                  Color(0xFF07070B)
                ])))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: step.color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: step.color.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: step.color.withOpacity(0.1),
                              blurRadius: 20)
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
                                    color: step.color.withOpacity(0.5),
                                    blurRadius: 15)
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
                          Text(step.arabicTitle,
                              style: TextStyle(
                                  color: step.color,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo')),
                          Text(step.arabicSubtitle,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontFamily: 'Cairo')),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E24).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: step.color.withOpacity(0.5)),
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
                      child: Text('اختر الهدف:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo')),
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
                            if (step.eventType == EventType.silence)
                              errorMsg = 'تم إسكاته سابقاً';
                            else if (step.eventType == EventType.protection)
                              errorMsg = 'تمت حمايته سابقاً';
                            else
                              errorMsg = 'غير متاح';
                          }

                          return GestureDetector(
                            onTap: canSelect
                                ? () {
                                    ref.read(audioManagerProvider).playClick();
                                    setState(
                                        () => _selectedPlayerId = player.id);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? step.color.withOpacity(0.15)
                                    : (canSelect
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black45),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? step.color
                                      : (canSelect
                                          ? Colors.white.withOpacity(0.1)
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
                                          color:
                                              Colors.redAccent.withOpacity(0.6),
                                          fontSize: 10,
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed:
                            _selectedPlayerId != null ? _confirmAction : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: step.color,
                          disabledBackgroundColor: Colors.white10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('تأكيد الإجراء',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: Colors.black)),
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
  const _InfoRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text('$label: ',
              style:
                  const TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  fontSize: 16)),
        ],
      );
}
