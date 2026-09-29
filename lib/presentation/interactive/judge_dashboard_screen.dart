import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';

class JudgeDashboardScreen extends ConsumerStatefulWidget {
  final String sessionId;
  
  const JudgeDashboardScreen({super.key, required this.sessionId});

  @override
  ConsumerState<JudgeDashboardScreen> createState() => _JudgeDashboardScreenState();
}

class _JudgeDashboardScreenState extends ConsumerState<JudgeDashboardScreen> {
  bool _isProcessing = false;

  void _syncStateToClients(Map<String, String>? requiredActions, Map<String, List<String>>? availableTargets) {
    ref.read(interactiveServiceProvider).syncGameState(widget.sessionId, ref.read(gameOrchestratorProvider), requiredActions, availableTargets);
  }

  Future<void> _startVoting(List<InteractiveSeat> seats) async {
    final orchestrator = ref.read(gameOrchestratorProvider.notifier);
    final state = ref.read(gameOrchestratorProvider);
    
    orchestrator.startVoting();
    
    final requiredActions = <String, String>{};
    final availableTargets = <String, List<String>>{};
    final aliveIds = state.alivePlayers.map((p) => p.id).toList();
    
    for (var p in state.alivePlayers) {
      requiredActions[p.id] = 'vote';
      availableTargets[p.id] = aliveIds.where((id) => id != p.id).toList(); 
    }
    
    _syncStateToClients(requiredActions, availableTargets);
  }

  Future<void> _resolveVoting(List<InteractiveSeat> seats, List<ActionRequest> actions) async {
    setState(() => _isProcessing = true);
    final service = ref.read(interactiveServiceProvider);
    final orchestrator = ref.read(gameOrchestratorProvider.notifier);
    
    try {
      final finalVotes = <String, String>{};
      for (var action in actions.where((a) => a.actionType == 'vote')) {
        final seat = seats.firstWhere((s) => s.linkedUid == action.uid);
        finalVotes[seat.id] = action.targetId;
        await service.clearActionRequest(widget.sessionId, action.id);
      }
      
      orchestrator.submitFinalVotes(finalVotes);
      final result = orchestrator.resolveVote();
      
      if (result['isTie'] == true) {
        orchestrator.revote();
        _syncStateToClients(null, null); // Optionally handle re-voting specifically
      } else {
        if (ref.read(gameOrchestratorProvider).phase == Phase.winCheck) {
          _syncStateToClients(null, null);
          return;
        }
        // If someone was eliminated, transition.
        _syncStateToClients(null, null);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _startNight(List<InteractiveSeat> seats) async {
    final orchestrator = ref.read(gameOrchestratorProvider.notifier);
    final state = ref.read(gameOrchestratorProvider);
    
    orchestrator.advanceToNight();
    
    final requiredActions = <String, String>{};
    final availableTargets = <String, List<String>>{};
    final aliveIds = state.alivePlayers.map((p) => p.id).toList();
    
    // Assign night actions exactly like local game
    final mafiaSheikh = state.alivePlayers.where((p) => p.role == Role.mafiaSheikh).firstOrNull;
    final anyMafia = state.alivePlayers.where((p) => p.role.team == Team.mafia).firstOrNull;
    final killer = mafiaSheikh ?? anyMafia;
    
    if (killer != null) {
      requiredActions[killer.id] = 'assassination';
      availableTargets[killer.id] = aliveIds.where((id) => state.players.firstWhere((p) => p.id == id).role.team != Team.mafia).toList();
    }
    
    final mafiaGirl = state.alivePlayers.where((p) => p.role == Role.mafiaGirl).firstOrNull;
    if (mafiaGirl != null) {
      requiredActions[mafiaGirl.id] = 'silence';
      availableTargets[mafiaGirl.id] = aliveIds;
    }
    
    final citizensSheikh = state.alivePlayers.where((p) => p.role == Role.citizensSheikh).firstOrNull;
    if (citizensSheikh != null) {
      requiredActions[citizensSheikh.id] = 'investigation';
      availableTargets[citizensSheikh.id] = aliveIds.where((id) => id != citizensSheikh.id).toList();
    }
    
    final citizensGirl = state.alivePlayers.where((p) => p.role == Role.citizensGirl).firstOrNull;
    if (citizensGirl != null) {
      requiredActions[citizensGirl.id] = 'protection';
      availableTargets[citizensGirl.id] = aliveIds;
    }
    
    _syncStateToClients(requiredActions, availableTargets);
  }

  Future<void> _resolveNight(List<InteractiveSeat> seats, List<ActionRequest> actions) async {
    setState(() => _isProcessing = true);
    final service = ref.read(interactiveServiceProvider);
    final orchestrator = ref.read(gameOrchestratorProvider.notifier);
    
    try {
      for (var action in actions.where((a) => a.actionType != 'vote')) {
        final seat = seats.firstWhere((s) => s.linkedUid == action.uid);
        
        EventType? type;
        if (action.actionType == 'assassination') type = EventType.assassination;
        else if (action.actionType == 'protection') type = EventType.protection;
        else if (action.actionType == 'investigation') type = EventType.investigation;
        else if (action.actionType == 'silence') type = EventType.silence;
        
        if (type != null) {
          orchestrator.submitNightAction(actorId: seat.id, targetId: action.targetId, type: type);
        }
        
        await service.clearActionRequest(widget.sessionId, action.id);
      }
      
      orchestrator.resolveNight();
      _syncStateToClients(null, null);
      
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameOrchestratorProvider);
    final service = ref.watch(interactiveServiceProvider);

    if (state.phase == Phase.winCheck) {
      return const Scaffold(
        body: Center(
          child: Text('اللعبة انتهت! تحقق من شاشة الفوز الرئيسية.', style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        title: Text('لوحة الحكم - ${state.phase.name}', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<InteractiveSeat>>(
        stream: service.streamSeats(widget.sessionId),
        builder: (context, seatsSnap) {
          final seats = seatsSnap.data ?? [];
          
          return StreamBuilder<List<ActionRequest>>(
            stream: service.streamActionRequests(widget.sessionId),
            builder: (context, actionsSnap) {
              final actions = actionsSnap.data ?? [];
              
              // Calculate who needs to submit
              final playersNeedingAction = state.alivePlayers.where((p) {
                if (state.phase == Phase.voting) return true;
                if (state.phase == Phase.night) {
                  final mafiaSheikh = state.alivePlayers.where((ap) => ap.role == Role.mafiaSheikh).firstOrNull;
                  final anyMafia = state.alivePlayers.where((ap) => ap.role.team == Team.mafia).firstOrNull;
                  final killer = mafiaSheikh ?? anyMafia;
                  if (p.id == killer?.id) return true;
                  if (p.role == Role.mafiaGirl) return true;
                  if (p.role == Role.citizensSheikh) return true;
                  if (p.role == Role.citizensGirl) return true;
                }
                return false;
              }).toList();
              
              final completedCount = actions.length;
              final isReadyToResolve = completedCount >= playersNeedingAction.length && playersNeedingAction.isNotEmpty;
              
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('الحالة: ${state.phase.name}', style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Cairo')),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.alivePlayers.length,
                        itemBuilder: (context, index) {
                          final player = state.alivePlayers[index];
                          final hasSubmitted = actions.any((a) {
                            final seat = seats.firstWhere((s) => s.linkedUid == a.uid, orElse: () => InteractiveSeat(id: '', playerName: '', isAlive: true, status: SeatStatus.unlinked));
                            return seat.id == player.id;
                          });
                          final needsAction = playersNeedingAction.contains(player);
                          
                          return ListTile(
                            title: Text(player.name, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                            subtitle: Text(player.role.name, style: const TextStyle(color: Colors.orangeAccent)),
                            trailing: needsAction 
                                ? Icon(hasSubmitted ? Icons.check_circle : Icons.hourglass_empty, color: hasSubmitted ? Colors.green : Colors.grey)
                                : const Icon(Icons.nightlight_round, color: Colors.blueGrey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (state.phase == Phase.day)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, minimumSize: const Size(double.infinity, 50)),
                        onPressed: _isProcessing ? null : () => _startVoting(seats),
                        child: const Text('بدء التصويت', style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                    if (state.phase == Phase.voting)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isReadyToResolve ? Colors.green : Colors.grey, minimumSize: const Size(double.infinity, 50)),
                        onPressed: (_isProcessing || !isReadyToResolve) ? null : () => _resolveVoting(seats, actions),
                        child: const Text('حسم التصويت', style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                    if (state.phase == Phase.elimination)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, minimumSize: const Size(double.infinity, 50)),
                        onPressed: _isProcessing ? null : () => _startNight(seats),
                        child: const Text('بدء الليل', style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                    if (state.phase == Phase.night)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isReadyToResolve ? Colors.green : Colors.grey, minimumSize: const Size(double.infinity, 50)),
                        onPressed: (_isProcessing || !isReadyToResolve) ? null : () => _resolveNight(seats, actions),
                        child: const Text('إنهاء الليل', style: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
