import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/day/day_screen.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';

class NightSummaryScreen extends ConsumerStatefulWidget {
  const NightSummaryScreen({super.key});

  @override
  ConsumerState<NightSummaryScreen> createState() => _NightSummaryScreenState();
}

class _NightSummaryScreenState extends ConsumerState<NightSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(gameOrchestratorProvider);
      final summaryEvent = state.eventHistory.where((e) => e.type == EventType.nightResolutionSummary).lastOrNull;
      if (summaryEvent != null) {
        final deadIds = (summaryEvent.metadata['assassinatedIds'] as List?)?.cast<String>() ?? [];
        if (deadIds.isNotEmpty) {
          ref.read(audioManagerProvider).playKill();
        }
      }
    });
  }

  void _goToDay() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DayScreen()));
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
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bolt, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('رد فعل المواطن الشجاع!', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('بما أنك قُتلت، يمكنك أخذ لاعب معك:', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
              const SizedBox(height: 12),
              ...alive.map((p) => RadioListTile<String>(
                    title: Text(p.name, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                    value: p.id,
                    groupValue: selectedId,
                    activeColor: Colors.orangeAccent,
                    onChanged: (v) => setDialogState(() => selectedId = v),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _goToDay();
              },
              child: const Text('تخطّي', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: selectedId != null
                  ? () {
                      Navigator.pop(ctx);
                      final targetPlayer = state.getPlayerById(selectedId!);
                      
                      ref.read(gameOrchestratorProvider.notifier).citizenBoyRetaliation(
                            actorId: actorId,
                            targetId: selectedId!,
                            nextPhase: Phase.day, 
                          );
                          
                      if (targetPlayer != null) {
                        _showRetaliationResultDialog(targetPlayer);
                      } else {
                        _routeAfterRetaliation();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
              child: const Text('تأكيد واغتيال', style: TextStyle(color: Colors.black, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _routeAfterRetaliation() {
    final newState = ref.read(gameOrchestratorProvider);
    if (newState.phase == Phase.winCheck) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameOverScreen()));
    } else {
      _goToDay();
    }
  }

  void _showRetaliationResultDialog(Player target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 2)),
        title: const Text('ضحية المواطن الشجاع!', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
            Text(target.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Text('كان: ${AppTheme.roleArabicName(target.role)}', style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (target.role == Role.citizensBoy) {
                _showCitizenBoyDialog(target.id);
              } else {
                _routeAfterRetaliation();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('متابعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameOrchestratorProvider);
    
    if (state.phase == Phase.winCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameOverScreen()));
      });
      return const Scaffold();
    }

    final summaryEvent = state.eventHistory.lastWhere(
      (e) => e.type == EventType.nightResolutionSummary,
      orElse: () => GameEvent(
        id: '',
        gameId: '',
        round: state.round,
        phase: Phase.nightResolution,
        type: EventType.nightResolutionSummary,
        timestamp: DateTime.now(),
      ),
    );

    final assassinatedIds = (summaryEvent.metadata['assassinatedIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final protectedIds = (summaryEvent.metadata['protectedIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final silencedIds = (summaryEvent.metadata['silencedIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final successfulProtections = (summaryEvent.metadata['successfulProtections'] as List<dynamic>?)?.cast<String>() ?? [];

    String getNames(List<String> ids) {
      if (ids.isEmpty) return 'لا أحد';
      return ids.map((id) => state.getPlayerById(id)?.name ?? 'مجهول').join('، ');
    }

    return GamePopScope(
      child: Scaffold(
        backgroundColor: const Color(0xFF07070B),
        appBar: AppBar(
          title: const Text('ملخص الليل (للحكم فقط)', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.5, colors: [Color(0xFF151826), Color(0xFF07070B)])))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.wb_twilight, size: 80, color: Colors.orangeAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'انتهى الليل، وإليك ما حدث في العتمة:',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    if (successfulProtections.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_moon, color: Colors.greenAccent, size: 40),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text('بنت المواطنين حمت الهدف بنجاح! لم يُقتل أحد.', style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            ),
                          ],
                        ),
                      ),

                    if (assassinatedIds.isNotEmpty)
                      ...assassinatedIds.map((id) {
                        final player = state.getPlayerById(id);
                        if (player == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.roleColor(player.role).withValues(alpha: 0.5), width: 2),
                          ),
                          child: Column(
                            children: [
                              const Text('ضحية الليل (تم اغتياله):', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.roleColor(player.role), width: 3),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    AppTheme.roleImage(player.role),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                player.name,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              ),
                              Text(
                                AppTheme.roleArabicName(player.role),
                                style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                        );
                      }),

                    if (silencedIds.isNotEmpty)
                      _SummaryCard(
                        title: 'تم إسكاتهم (لا يحق لهم الكلام):',
                        names: getNames(silencedIds),
                        icon: Icons.volume_off,
                        color: Colors.blueAccent,
                      ),
                    
                    const Spacer(),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (state.phase == Phase.triggeredAbility && assassinatedIds.isNotEmpty) {
                            _showCitizenBoyDialog(assassinatedIds.first);
                          } else {
                            _goToDay();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.phase == Phase.triggeredAbility ? Colors.orangeAccent : Colors.orangeAccent,
                          elevation: 10,
                          shadowColor: Colors.orangeAccent.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          state.phase == Phase.triggeredAbility ? 'رد فعل المواطن الشجاع!' : 'بدء النهار', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.black)
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String names;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.names,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 4),
                Text(names, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
