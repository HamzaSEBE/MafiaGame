import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/session_exit_confirmation.dart';

class JudgeDashboardScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const JudgeDashboardScreen({super.key, required this.sessionId});

  @override
  ConsumerState<JudgeDashboardScreen> createState() =>
      _JudgeDashboardScreenState();
}

class _JudgeDashboardScreenState extends ConsumerState<JudgeDashboardScreen> {
  bool _isProcessing = false;
  bool _isExiting = false;
  String? _retaliationActorId;
  String? _retaliationTargetId;
  Phase? _retaliationNextPhase;

  Future<void> _syncStateToClients(
    Map<String, String>? requiredActions,
    Map<String, List<String>>? availableTargets,
  ) {
    return ref.read(interactiveServiceProvider).syncGameState(
          widget.sessionId,
          ref.read(gameOrchestratorProvider),
          requiredActions,
          availableTargets,
        );
  }

  Future<void> _runHostAction(Future<void> Function() action) async {
    if (_isProcessing || _isExiting) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث اللعبة: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _beginDay() => _runHostAction(() async {
        ref.read(gameOrchestratorProvider.notifier).beginDay();
        await _syncStateToClients(null, null);
      });

  Future<void> _startVoting() => _runHostAction(_publishVotingActions);

  Future<void> _publishVotingActions() async {
    final orchestrator = ref.read(gameOrchestratorProvider.notifier);
    orchestrator.startVoting();
    final state = ref.read(gameOrchestratorProvider);
    final aliveIds = state.alivePlayers.map((player) => player.id).toList();
    final requiredActions = <String, String>{};
    final availableTargets = <String, List<String>>{};

    for (final player in state.alivePlayers) {
      requiredActions[player.id] = 'vote';
      availableTargets[player.id] =
          aliveIds.where((id) => id != player.id).toList();
    }

    await _syncStateToClients(requiredActions, availableTargets);
  }

  Future<void> _resolveVoting(
    List<InteractiveSeat> seats,
    List<ActionRequest> actions,
  ) {
    return _runHostAction(() async {
      final service = ref.read(interactiveServiceProvider);
      final orchestrator = ref.read(gameOrchestratorProvider.notifier);
      final finalVotes = <String, String>{};

      for (final action
          in actions.where((action) => action.actionType == 'vote')) {
        final seat = _seatForUid(seats, action.uid);
        if (seat != null) finalVotes[seat.id] = action.targetId;
        await service.clearActionRequest(widget.sessionId, action.id);
      }

      orchestrator.submitFinalVotes(finalVotes);
      final result = orchestrator.resolveVote();
      final state = ref.read(gameOrchestratorProvider);

      if (result['isTie'] == true) {
        // A tie is a new vote. Restore vote choices instead of leaving every
        // player on the "wait for your turn" screen.
        orchestrator.revote();
        _retaliationActorId = null;
        _retaliationNextPhase = null;
        await _publishVotingActions();
        return;
      }

      if (state.phase == Phase.triggeredAbility) {
        final elimination = state.eventHistory.lastWhere(
          (event) =>
              event.type == EventType.elimination && event.round == state.round,
        );
        _retaliationActorId = elimination.targetId;
        _retaliationNextPhase = Phase.night;
      } else {
        _retaliationActorId = null;
        _retaliationNextPhase = null;
      }

      await _syncStateToClients(null, null);
    });
  }

  Future<void> _startNight() => _runHostAction(() async {
        final orchestrator = ref.read(gameOrchestratorProvider.notifier);
        orchestrator.advanceToNight();
        final state = ref.read(gameOrchestratorProvider);
        final aliveIds = state.alivePlayers.map((player) => player.id).toList();
        final requiredActions = <String, String>{};
        final availableTargets = <String, List<String>>{};

        final mafiaSheikh = state.alivePlayers
            .where((player) => player.role == Role.mafiaSheikh)
            .firstOrNull;
        final anyMafia = state.alivePlayers
            .where((player) => player.role.team == Team.mafia)
            .firstOrNull;
        final killer = mafiaSheikh ?? anyMafia;

        if (killer != null) {
          final targets = state.alivePlayers
              .where((player) => player.role.team != Team.mafia)
              .map((player) => player.id)
              .toList();
          if (targets.isNotEmpty) {
            requiredActions[killer.id] = 'assassination';
            availableTargets[killer.id] = targets;
          }
        }

        final mafiaGirl = state.alivePlayers
            .where((player) => player.role == Role.mafiaGirl)
            .firstOrNull;
        if (mafiaGirl != null && aliveIds.isNotEmpty) {
          requiredActions[mafiaGirl.id] = 'silence';
          availableTargets[mafiaGirl.id] = aliveIds;
        }

        final citizensSheikh = state.alivePlayers
            .where((player) => player.role == Role.citizensSheikh)
            .firstOrNull;
        if (citizensSheikh != null) {
          final targets =
              aliveIds.where((id) => id != citizensSheikh.id).toList();
          if (targets.isNotEmpty) {
            requiredActions[citizensSheikh.id] = 'investigation';
            availableTargets[citizensSheikh.id] = targets;
          }
        }

        final citizensGirl = state.alivePlayers
            .where((player) => player.role == Role.citizensGirl)
            .firstOrNull;
        if (citizensGirl != null && aliveIds.isNotEmpty) {
          requiredActions[citizensGirl.id] = 'protection';
          availableTargets[citizensGirl.id] = aliveIds;
        }

        await _syncStateToClients(requiredActions, availableTargets);
      });

  Future<void> _resolveNight(
    List<InteractiveSeat> seats,
    List<ActionRequest> actions,
  ) {
    return _runHostAction(() async {
      final service = ref.read(interactiveServiceProvider);
      final orchestrator = ref.read(gameOrchestratorProvider.notifier);

      for (final action
          in actions.where((action) => action.actionType != 'vote')) {
        final seat = _seatForUid(seats, action.uid);
        final type = switch (action.actionType) {
          'assassination' => EventType.assassination,
          'protection' => EventType.protection,
          'investigation' => EventType.investigation,
          'silence' => EventType.silence,
          _ => null,
        };

        if (seat != null && type != null) {
          orchestrator.submitNightAction(
            actorId: seat.id,
            targetId: action.targetId,
            type: type,
          );
        }
        await service.clearActionRequest(widget.sessionId, action.id);
      }

      orchestrator.resolveNight();
      final state = ref.read(gameOrchestratorProvider);
      if (state.phase == Phase.triggeredAbility) {
        final summary = state.eventHistory.lastWhere(
          (event) =>
              event.type == EventType.nightResolutionSummary &&
              event.round == state.round,
        );
        final deceasedIds =
            List<String>.from(summary.metadata['assassinatedIds'] ?? const []);
        _retaliationActorId = state.players
            .where((player) =>
                deceasedIds.contains(player.id) &&
                player.role == Role.citizensBoy)
            .firstOrNull
            ?.id;
        _retaliationNextPhase = Phase.day;
      } else {
        _retaliationActorId = null;
        _retaliationNextPhase = null;
      }

      await _syncStateToClients(null, null);
    });
  }

  Future<void> _resolveRetaliation() => _runHostAction(() async {
        final actorId = _retaliationActorId;
        final targetId = _retaliationTargetId;
        final nextPhase = _retaliationNextPhase;
        if (actorId == null || targetId == null || nextPhase == null) return;

        ref.read(gameOrchestratorProvider.notifier).citizenBoyRetaliation(
              actorId: actorId,
              targetId: targetId,
              nextPhase: nextPhase,
            );
        _retaliationActorId = null;
        _retaliationTargetId = null;
        _retaliationNextPhase = null;
        await _syncStateToClients(null, null);
      });

  Future<void> _confirmEndSession() async {
    if (_isExiting || _isProcessing) return;
    final confirmed = await confirmEndInteractiveSession(context);
    if (!confirmed || !mounted) return;

    setState(() => _isExiting = true);
    try {
      await ref
          .read(interactiveServiceProvider)
          .endSession(widget.sessionId)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      ref.read(gameOrchestratorProvider.notifier).resetGame();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isExiting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنهاء الجلسة. أعد المحاولة: $error')),
      );
    }
  }

  InteractiveSeat? _seatForUid(List<InteractiveSeat> seats, String uid) {
    for (final seat in seats) {
      if (seat.linkedUid == uid) return seat;
    }
    return null;
  }

  String _phaseLabel(Phase phase) => switch (phase) {
        Phase.roleReveal => 'كشف الأدوار',
        Phase.day => 'النهار',
        Phase.voting => 'التصويت',
        Phase.elimination => 'الإقصاء',
        Phase.night => 'الليل',
        Phase.triggeredAbility => 'قدرة الانتقام',
        Phase.winCheck => 'انتهت اللعبة',
        _ => phase.name,
      };

  Widget _exitButton() => IconButton(
        tooltip: 'إنهاء اللعبة وإخراج اللاعبين',
        onPressed: _isExiting || _isProcessing ? null : _confirmEndSession,
        icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameOrchestratorProvider);
    final service = ref.watch(interactiveServiceProvider);

    if (state.phase == Phase.winCheck) {
      return Scaffold(
        backgroundColor: const Color(0xFF07070B),
        appBar: AppBar(
          title:
              const Text('انتهت اللعبة', style: TextStyle(fontFamily: 'Cairo')),
          actions: [_exitButton()],
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events,
                    color: Colors.orangeAccent, size: 76),
                const SizedBox(height: 16),
                Text(
                  'الفائز: ${state.winner?.name ?? 'غير محدد'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed:
                      _isExiting || _isProcessing ? null : _confirmEndSession,
                  icon: const Icon(Icons.home),
                  label: const Text('إنهاء الجلسة والعودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'العودة إلى ساحة اللاعبين',
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'لوحة الحكم - ${_phaseLabel(state.phase)}',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [_exitButton()],
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<InteractiveSeat>>(
        stream: service.streamSeats(widget.sessionId),
        builder: (context, seatsSnap) {
          if (seatsSnap.hasError) {
            return _error('تعذر تحميل المقاعد: ${seatsSnap.error}');
          }
          if (!seatsSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }
          final seats = seatsSnap.data!;

          return StreamBuilder<List<ActionRequest>>(
            stream: service.streamActionRequests(widget.sessionId),
            builder: (context, actionsSnap) {
              if (actionsSnap.hasError) {
                return _error(
                    'تعذر تحميل حركات اللاعبين: ${actionsSnap.error}');
              }
              final actions = actionsSnap.data ?? const <ActionRequest>[];
              final playersNeedingAction = _playersNeedingAction(state);
              final submittedPlayerIds = <String>{};
              for (final action in actions) {
                final seat = _seatForUid(seats, action.uid);
                if (seat != null) submittedPlayerIds.add(seat.id);
              }
              final isReadyToResolve = playersNeedingAction.isNotEmpty &&
                  playersNeedingAction.every(
                      (player) => submittedPlayerIds.contains(player.id));

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'الحالة: ${_phaseLabel(state.phase)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.alivePlayers.length,
                        itemBuilder: (context, index) {
                          final player = state.alivePlayers[index];
                          final hasSubmitted =
                              submittedPlayerIds.contains(player.id);
                          final needsAction =
                              playersNeedingAction.contains(player);

                          return ListTile(
                            title: Text(
                              player.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            subtitle: Text(
                              player.role.name,
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                              ),
                            ),
                            trailing: needsAction
                                ? Icon(
                                    hasSubmitted
                                        ? Icons.check_circle
                                        : Icons.hourglass_empty,
                                    color: hasSubmitted
                                        ? Colors.green
                                        : Colors.grey,
                                  )
                                : const Icon(
                                    Icons.nightlight_round,
                                    color: Colors.blueGrey,
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.phase == Phase.roleReveal)
                      _phaseButton(
                        label: 'انتهى كشف الأدوار — ابدأ النهار',
                        onPressed: _beginDay,
                      ),
                    if (state.phase == Phase.day)
                      _phaseButton(
                        label: 'بدء التصويت',
                        onPressed: _startVoting,
                      ),
                    if (state.phase == Phase.voting)
                      _phaseButton(
                        label: 'حسم التصويت',
                        enabled: isReadyToResolve,
                        onPressed: () => _resolveVoting(seats, actions),
                      ),
                    if (state.phase == Phase.elimination)
                      _phaseButton(
                        label: 'بدء الليل',
                        onPressed: _startNight,
                      ),
                    if (state.phase == Phase.night)
                      _phaseButton(
                        label: 'إنهاء الليل',
                        enabled: isReadyToResolve,
                        onPressed: () => _resolveNight(seats, actions),
                      ),
                    if (state.phase == Phase.triggeredAbility)
                      _buildRetaliationControls(state),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Player> _playersNeedingAction(GameState state) {
    if (state.phase == Phase.voting) return state.alivePlayers;
    if (state.phase != Phase.night) return const [];

    final mafiaSheikh = state.alivePlayers
        .where((player) => player.role == Role.mafiaSheikh)
        .firstOrNull;
    final anyMafia = state.alivePlayers
        .where((player) => player.role.team == Team.mafia)
        .firstOrNull;
    final killer = mafiaSheikh ?? anyMafia;
    return state.alivePlayers.where((player) {
      return player.id == killer?.id ||
          player.role == Role.mafiaGirl ||
          player.role == Role.citizensSheikh ||
          player.role == Role.citizensGirl;
    }).toList();
  }

  Widget _buildRetaliationControls(GameState state) {
    final targets = state.alivePlayers;
    final actor = state.getPlayerById(_retaliationActorId ?? '');
    if (actor == null || _retaliationNextPhase == null) {
      return _phaseButton(
        label: 'متابعة اللعبة',
        onPressed: _skipMissingRetaliation,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'قُتل ${actor.name} صاحب قدرة الانتقام. اختر لاعبًا حيًا ليقصيه:',
          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: targets.any((player) => player.id == _retaliationTargetId)
              ? _retaliationTargetId
              : null,
          hint: const Text(
            'اختر اللاعب',
            style: TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
          ),
          dropdownColor: const Color(0xFF1A1A22),
          isExpanded: true,
          items: targets
              .map((player) => DropdownMenuItem<String>(
                    value: player.id,
                    child: Text(
                      player.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ))
              .toList(),
          onChanged: _isProcessing
              ? null
              : (value) => setState(() => _retaliationTargetId = value),
        ),
        const SizedBox(height: 8),
        _phaseButton(
          label: 'تنفيذ الانتقام ومتابعة اللعبة',
          enabled: _retaliationTargetId != null,
          onPressed: _resolveRetaliation,
        ),
      ],
    );
  }

  Future<void> _skipMissingRetaliation() => _runHostAction(() async {
        final nextPhase = _retaliationNextPhase;
        if (nextPhase == null) return;
        ref
            .read(gameOrchestratorProvider.notifier)
            .skipTriggeredAbility(nextPhase);
        _retaliationActorId = null;
        _retaliationTargetId = null;
        _retaliationNextPhase = null;
        await _syncStateToClients(null, null);
      });

  Widget _phaseButton({
    required String label,
    required Future<void> Function() onPressed,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.orangeAccent : Colors.grey,
          minimumSize: const Size(double.infinity, 52),
        ),
        onPressed: _isProcessing || !enabled ? null : onPressed,
        child: _isProcessing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _error(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.redAccent, fontFamily: 'Cairo'),
          ),
        ),
      );
}
