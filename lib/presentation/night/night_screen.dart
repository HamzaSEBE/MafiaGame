import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/night/night_summary_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

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
  const NightScreen({super.key});

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
      // Start night music
      Future.microtask(() => ref.read(audioManagerProvider).playNightMusic());
    }
  }

  @override
  void dispose() {
    // We shouldn't stop music here if we want it to continue to NightSummary, 
    // but usually day starts next. Let's stop it in the next screen.
    super.dispose();
  }

  void _buildActiveSteps() {
    final state = ref.read(gameOrchestratorProvider);
    final alivePlayers = state.alivePlayers;
    _activeSteps = [];

    // Night 1: Only Mafia wakes up, no actions
    if (state.round == 1) {
      return; 
    }

    // 1. Assassination Step (Mafia Hierarchy)
    final sheikh = alivePlayers.where((p) => p.role == Role.mafiaSheikh).firstOrNull;
    final girl = alivePlayers.where((p) => p.role == Role.mafiaGirl).firstOrNull;
    final normal = alivePlayers.where((p) => p.role == Role.normalMafia).firstOrNull;
    
    Player? assassinationActor = sheikh ?? girl ?? normal;
    
    if (assassinationActor != null) {
      String title = 'الاغتيال';
      String subtitle = assassinationActor.role == Role.mafiaSheikh 
          ? 'بواسطة شيخ المافيا' 
          : (assassinationActor.role == Role.mafiaGirl ? 'بواسطة بنت المافيا (بالنيابة)' : 'بواسطة المافيا العادية (بالنيابة)');
      
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
        color: AppTheme.mafiaAccent,
        eventType: EventType.assassination,
      ));
    }

    // 2. Silence Step (Mafia Girl)
    if (girl != null) {
      _activeSteps.add(_DynamicNightStep(
        actor: girl,
        arabicTitle: 'الإسكات',
        arabicSubtitle: 'بواسطة بنت المافيا',
        arabicAction: '"يا بنت المافيا افتحي عينيكِ... اختاري من ستُسكتين... أغمضي عينيكِ"',
        color: AppTheme.mafiaPrimary,
        eventType: EventType.silence,
      ));
    }

    // 3. Investigation Step (Citizen Sheikh)
    final citizenSheikh = alivePlayers.where((p) => p.role == Role.citizensSheikh).firstOrNull;
    if (citizenSheikh != null) {
      _activeSteps.add(_DynamicNightStep(
        actor: citizenSheikh,
        arabicTitle: 'التحقيق',
        arabicSubtitle: 'بواسطة شيخ المواطنين',
        arabicAction: '"يا شيخ المواطنين افتح عينيك... اختر من تريد التحقيق عنه... أغمض عينيك"',
        color: AppTheme.citizensAccent,
        eventType: EventType.investigation,
      ));
    }

    // 4. Protection Step (Citizen Girl)
    final citizenGirl = alivePlayers.where((p) => p.role == Role.citizensGirl).firstOrNull;
    if (citizenGirl != null) {
      _activeSteps.add(_DynamicNightStep(
        actor: citizenGirl,
        arabicTitle: 'الحماية',
        arabicSubtitle: 'بواسطة بنت المواطنين',
        arabicAction: '"يا بنت المواطنين افتحي عينيكِ... اختاري من ستحمين... أغمضي عينيكِ"',
        color: AppTheme.citizensPrimary,
        eventType: EventType.protection,
      ));
    }
  }

  bool _canSelectTarget(Player target, _DynamicNightStep step) {
    final state = ref.read(gameOrchestratorProvider);
    
    // Assassination: Cannot target self or mafia members
    if (step.eventType == EventType.assassination) {
      if (target.id == step.actor.id) return false;
      if (target.role.team == Team.mafia) return false;
    }
    
    // Silence: Cannot target someone already silenced by this actor before (Lifetime restriction)
    if (step.eventType == EventType.silence) {
      final pastSilences = state.eventHistory.where((e) => 
        e.type == EventType.silence && e.actorId == step.actor.id && e.targetId == target.id
      );
      if (pastSilences.isNotEmpty) return false;
    }
    
    // Protection: Cannot target someone already protected by this actor before (Lifetime restriction)
    if (step.eventType == EventType.protection) {
      final pastProtections = state.eventHistory.where((e) => 
        e.type == EventType.protection && e.actorId == step.actor.id && e.targetId == target.id
      );
      if (pastProtections.isNotEmpty) return false;
    }
    
    // Investigation: Cannot investigate self
    if (step.eventType == EventType.investigation) {
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
        final target = ref.read(gameOrchestratorProvider).getPlayerById(_selectedPlayerId!);
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تأكيد الإجراء', style: TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'الإجراء', value: step.arabicTitle, color: step.color),
              const SizedBox(height: 4),
              _InfoRow(label: 'بواسطة', value: step.actor.name, color: AppTheme.textSecondary),
              const SizedBox(height: 12),
              _InfoRow(label: 'الهدف', value: target?.name ?? '—', color: AppTheme.textPrimary),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary)),
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
                  _advance();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: step.color),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  void _showInvestigationResult(Player target) {
    final isMafia = target.role.team == Team.mafia;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isMafia ? AppTheme.mafiaPrimary : AppTheme.citizensPrimary, width: 2)),
        title: Row(
          children: [
            Icon(isMafia ? Icons.warning_amber_rounded : Icons.verified_user, color: isMafia ? AppTheme.mafiaPrimary : AppTheme.citizensPrimary),
            const SizedBox(width: 8),
            Text('نتيجة التحقيق', style: TextStyle(color: isMafia ? AppTheme.mafiaPrimary : AppTheme.citizensPrimary, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اللاعب ${target.name}', style: const TextStyle(fontSize: 20, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              isMafia ? 'من المافيا! (أومئ برأسك بنعم)' : 'مواطن بريء! (أومئ برأسك بلا)',
              style: TextStyle(
                fontSize: 18, 
                color: isMafia ? AppTheme.mafiaPrimary : AppTheme.citizensPrimary, 
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _advance();
            },
            style: ElevatedButton.styleFrom(backgroundColor: isMafia ? AppTheme.mafiaPrimary : AppTheme.citizensPrimary),
            child: const Text('فهمت، متابعة'),
          ),
        ],
      ),
    );
  }



  void _advance() {
    setState(() => _selectedPlayerId = null);
    if (_stepIndex < _activeSteps.length - 1) {
      setState(() => _stepIndex++);
    } else {
      ref.read(gameOrchestratorProvider.notifier).resolveNight();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NightSummaryScreen()),
      );
    }
  }

  void _goBack() {
    if (_stepIndex > 0) {
      // Undo the last action submitted to the game state
      ref.read(gameOrchestratorProvider.notifier).undoLastNightAction();
      setState(() {
        _stepIndex--;
        _selectedPlayerId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameOrchestratorProvider);
    final round = gameState.round;

    if (_activeSteps.isEmpty) {
      if (round == 1) {
        return Scaffold(
          appBar: AppBar(title: const Text('الليل 1 (تعارف)')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group, size: 80, color: AppTheme.mafiaAccent),
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, size: 48, color: AppTheme.mafiaPrimary),
                  onPressed: () => ref.read(audioManagerProvider).playVoiceover('night1_intro.mp3'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'بصوت عالي احكي:\n\nالكل يغمض عينيه\nالمافيا تفتح عينيها (للتعارف فقط)\nالمافيا تغمض\nالكل يفتح',
                  style: TextStyle(fontSize: 22, fontFamily: 'Cairo', height: 1.8, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    ref.read(gameOrchestratorProvider.notifier).resolveNight();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NightSummaryScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mafiaAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text('متابعة إلى النهار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text('الليل $round')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              ref.read(gameOrchestratorProvider.notifier).resolveNight();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NightSummaryScreen()));
            },
            child: const Text('إنهاء الليل'),
          ),
        ),
      );
    }

    final step = _activeSteps[_stepIndex];
    final targets = gameState.alivePlayers;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _stepIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
                onPressed: _goBack,
                tooltip: 'تراجع عن الإجراء السابق',
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nights_stay, size: 18),
            const SizedBox(width: 6),
            Text('الليل $round', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Row(
              children: [
                ...List.generate(_activeSteps.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: i == _stepIndex ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i < _stepIndex
                        ? AppTheme.success
                        : i == _stepIndex
                            ? step.color
                            : AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: AppTheme.error, size: 20),
                  tooltip: 'إنهاء اللعبة',
                  onPressed: () => _confirmExit(context, ref),
                ),
              ],
            ),
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
                color: step.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: step.color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: step.color.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: step.color, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppTheme.roleImage(step.actor.role),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(step.arabicTitle,
                      style: TextStyle(color: step.color, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
                  Text(step.arabicSubtitle,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontFamily: 'Cairo')),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, size: 36, color: step.color),
                    onPressed: () {
                      String voiceFile = 'action_${step.actor.role.name}.mp3';
                      ref.read(audioManagerProvider).playVoiceover(voiceFile);
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: step.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.mic, color: step.color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.arabicAction,
                            style: TextStyle(
                              color: AppTheme.textPrimary, 
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
              child: Text('اختر الهدف:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  
                  return GestureDetector(
                    onTap: canSelect ? () => setState(() => _selectedPlayerId = player.id) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? step.color.withValues(alpha: 0.15) 
                            : (canSelect ? AppTheme.surface : AppTheme.surface.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? step.color 
                              : (canSelect ? AppTheme.surfaceHigh : Colors.transparent),
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
                                  : (canSelect ? AppTheme.textPrimary : AppTheme.textSecondary.withValues(alpha: 0.4)),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Cairo',
                              decoration: canSelect ? TextDecoration.none : TextDecoration.lineThrough,
                            ),
                          ),
                          if (gameState.eventHistory.any((e) => e.type == EventType.protection && e.targetId == player.id))
                             Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Icon(Icons.shield, color: AppTheme.success.withValues(alpha: 0.8), size: 10),
                                 const SizedBox(width: 2),
                                 Text('تلقى حماية سابقة', style: TextStyle(color: AppTheme.success.withValues(alpha: 0.8), fontSize: 9, fontFamily: 'Cairo')),
                               ],
                             ),
                          if (!canSelect)
                             Text(
                              'غير متاح',
                              style: TextStyle(color: AppTheme.error.withValues(alpha: 0.6), fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedPlayerId != null ? _confirmAction : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.color,
                      disabledBackgroundColor: AppTheme.surfaceHigh,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('تأكيد الإجراء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      ),
      ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ],
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
