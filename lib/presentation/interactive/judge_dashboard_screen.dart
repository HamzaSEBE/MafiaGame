import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';

class JudgeDashboardScreen extends ConsumerStatefulWidget {
  final String sessionId;
  
  const JudgeDashboardScreen({super.key, required this.sessionId});

  @override
  ConsumerState<JudgeDashboardScreen> createState() => _JudgeDashboardScreenState();
}

class _JudgeDashboardScreenState extends ConsumerState<JudgeDashboardScreen> {
  bool _isProcessing = false;

  Future<void> _advancePhase(List<InteractiveSeat> seats, List<ActionRequest> actions) async {
    setState(() => _isProcessing = true);
    final service = ref.read(interactiveServiceProvider);
    final orchestrator = ref.read(gameOrchestratorProvider.notifier);
    final state = ref.read(gameOrchestratorProvider);

    try {
      if (state.phase == Phase.day) {
        orchestrator.startVoting();
        
        // Notify players to vote
        final requiredActions = <String, String>{};
        final availableTargets = <String, List<String>>{};
        final aliveIds = state.alivePlayers.map((p) => p.id).toList();
        
        for (var p in state.alivePlayers) {
          requiredActions[p.id] = 'vote';
          availableTargets[p.id] = aliveIds.where((id) => id != p.id).toList(); // Cannot vote self
        }
        
        await service.syncGameState(widget.sessionId, ref.read(gameOrchestratorProvider), requiredActions, availableTargets);
        
      } else if (state.phase == Phase.voting) {
        // Collect votes
        final finalVotes = <String, String>{};
        for (var action in actions.where((a) => a.actionType == 'vote')) {
          // Find seat for this uid
          final seat = seats.firstWhere((s) => s.linkedUid == action.uid);
          finalVotes[seat.id] = action.targetId;
          await service.clearActionRequest(widget.sessionId, action.id);
        }
        
        orchestrator.submitFinalVotes(finalVotes);
        final result = orchestrator.resolveVote();
        
        // Note: result['isTie'] might be true. If so, phase is still voting.
        
        await service.syncGameState(widget.sessionId, ref.read(gameOrchestratorProvider), null, null);
        
      } else if (state.phase == Phase.night) {
        // Collect night actions
        for (var action in actions.where((a) => a.actionType == 'night_action')) {
          final seat = seats.firstWhere((s) => s.linkedUid == action.uid);
          // Assuming the actionType encoded the eventType like 'assassination', 'protection'
          // We will store that in targetId for now or metadata.
          // For simplicity, let's just use orchestrator.submitNightAction
          // But wait, the night actions are sequential in the local game.
        }
        // ... I will need to build the night logic better.
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic scaffold for now, to ensure no build errors
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Dashboard Under Construction')),
    );
  }
}
