import 'dart:async';

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
import 'package:mafia_nightfall/presentation/day/day_screen.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/session_exit_confirmation.dart';
import 'package:mafia_nightfall/presentation/night/cinematic_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/voting/voting_screen.dart';

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
  bool _isOpeningGameOver = false;
  bool _isLoadingSessionState = true;
  final Set<int> _nightActionRounds = {};
  StreamSubscription<InteractiveSession?>? _sessionSubscription;
  StreamSubscription<List<InteractiveSeat>>? _seatsSubscription;
  StreamSubscription<List<ActionRequest>>? _actionsSubscription;
  InteractiveSession? _liveSession;
  List<InteractiveSeat> _liveSeats = const [];
  List<ActionRequest> _liveActions = const [];
  final Set<String> _pendingInvestigationResults = {};
  final Set<String> _publishedInvestigationResults = {};

  @override
  void initState() {
    super.initState();
    _watchForInvestigations();
    _restorePublishedActionState();
  }

  @override
  void dispose() {
    unawaited(_sessionSubscription?.cancel() ?? Future<void>.value());
    unawaited(_seatsSubscription?.cancel() ?? Future<void>.value());
    unawaited(_actionsSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  void _watchForInvestigations() {
    final service = ref.read(interactiveServiceProvider);
    _sessionSubscription = service.streamSession(widget.sessionId).listen(
      (session) {
        _liveSession = session;
        _publishAvailableInvestigationResults();
      },
      onError: (_) {},
    );
    _seatsSubscription = service.streamSeats(widget.sessionId).listen(
      (seats) {
        _liveSeats = seats;
        _publishAvailableInvestigationResults();
      },
      onError: (_) {},
    );
    _actionsSubscription =
        service.streamActionRequests(widget.sessionId).listen(
      (actions) {
        _liveActions = actions;
        _publishAvailableInvestigationResults();
      },
      onError: (_) {},
    );
  }

  Future<void> _publishAvailableInvestigationResults() async {
    if (!mounted) return;
    final session = _liveSession;
    final state = ref.read(gameOrchestratorProvider);
    if (session == null ||
        session.status != SessionStatus.active ||
        session.phase != Phase.night ||
        session.actionsPhase != Phase.night ||
        session.actionsRound != state.round ||
        session.round != state.round ||
        state.phase != Phase.night) {
      return;
    }

    final prompts = _nightPrompts(state);
    final service = ref.read(interactiveServiceProvider);
    for (final action in _liveActions) {
      if (action.actionType != 'investigation' ||
          action.revision != session.actionRevision ||
          _publishedInvestigationResults.contains(action.id) ||
          !_pendingInvestigationResults.add(action.id)) {
        continue;
      }

      final seat = _seatForUid(_liveSeats, action.uid);
      final actor = seat == null ? null : state.getPlayerById(seat.id);
      final target = state.getPlayerById(action.targetId);
      final prompt = seat == null
          ? null
          : prompts[seat.id]
              ?.where((item) => item.type == 'investigation')
              .firstOrNull;
      if (actor == null ||
          actor.role != Role.citizensSheikh ||
          !actor.isAlive ||
          target == null ||
          !target.isAlive ||
          target.id == actor.id ||
          prompt == null ||
          !prompt.availableTargets.contains(target.id)) {
        _pendingInvestigationResults.remove(action.id);
        continue;
      }

      final result =
          'اللاعب ${target.name} ${target.role.team == Team.mafia ? 'من المافيا!' : 'من المواطنين'}';
      try {
        final published = await service.publishInvestigationResult(
          sessionId: widget.sessionId,
          seatId: actor.id,
          expectedRevision: session.actionRevision,
          expectedRound: state.round,
          result: result,
        );
        if (published) _publishedInvestigationResults.add(action.id);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر إرسال نتيجة التحقيق فورًا: $error')),
          );
        }
      } finally {
        _pendingInvestigationResults.remove(action.id);
      }
    }
  }

  Future<void> _restorePublishedActionState() async {
    try {
      final session = await ref
          .read(interactiveServiceProvider)
          .getSession(widget.sessionId);
      final state = ref.read(gameOrchestratorProvider);
      if (mounted &&
          session?.actionsPhase == Phase.night &&
          session?.actionsRound == state.round) {
        setState(() => _nightActionRounds.add(state.round));
      }
    } catch (_) {
      // Keep the dashboard available; the live session stream reports errors.
    } finally {
      if (mounted) setState(() => _isLoadingSessionState = false);
    }
  }

  Future<void> _syncStateToClients({
    Map<String, List<PlayerActionPrompt>>? actionPrompts,
    Map<String, String>? privateResults,
    bool clearPrivateResults = false,
  }) {
    return ref.read(interactiveServiceProvider).syncGameState(
          widget.sessionId,
          ref.read(gameOrchestratorProvider),
          null,
          null,
          actionPrompts: actionPrompts,
          privateResults: privateResults,
          clearPrivateResults: clearPrivateResults,
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

  Future<void> _beginIntroductionNight() => _runHostAction(() async {
        final service = ref.read(interactiveServiceProvider);
        await service.clearActionRequests(widget.sessionId);
        ref.read(gameOrchestratorProvider.notifier).beginIntroductionNight();
        await _syncStateToClients(clearPrivateResults: true);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NightScreen(
              interactiveSessionId: widget.sessionId,
              onInteractiveExit: _confirmEndSession,
            ),
          ),
        );
      });

  Future<void> _openDayDiscussion() async {
    if (_isProcessing || _isExiting) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DayScreen(
          interactiveSessionId: widget.sessionId,
          onInteractiveStartVoting: _startVoting,
          onInteractiveExit: _confirmEndSession,
        ),
      ),
    );
  }

  Future<void> _startVoting() async {
    if (_isProcessing || _isExiting) return;
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(interactiveServiceProvider);
      await service.clearActionRequests(widget.sessionId);
      ref.read(gameOrchestratorProvider.notifier).startVoting();
      final state = ref.read(gameOrchestratorProvider);
      await _syncStateToClients(actionPrompts: _votingPrompts(state));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VotingScreen(
            interactiveSessionId: widget.sessionId,
            onInteractiveExit: _confirmEndSession,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر بدء التصويت: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _resumeVotingCourt() async {
    if (_isProcessing || _isExiting) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VotingScreen(
          interactiveSessionId: widget.sessionId,
          onInteractiveExit: _confirmEndSession,
        ),
      ),
    );
  }

  Map<String, List<PlayerActionPrompt>> _votingPrompts(GameState state) {
    final prompts = <String, List<PlayerActionPrompt>>{};
    final aliveIds = state.alivePlayers.map((player) => player.id).toList();
    for (final player in state.alivePlayers) {
      final targets = aliveIds.where((id) => id != player.id).toList();
      if (targets.isNotEmpty) {
        prompts[player.id] = [
          PlayerActionPrompt(type: 'vote', availableTargets: targets),
        ];
      }
    }
    return prompts;
  }

  Map<String, List<PlayerActionPrompt>> _nightPrompts(GameState state) {
    final prompts = <String, List<PlayerActionPrompt>>{};
    final alive = state.alivePlayers;
    final aliveIds = alive.map((player) => player.id).toList();

    final sheikh = alive.where((p) => p.role == Role.mafiaSheikh).firstOrNull;
    final girl = alive.where((p) => p.role == Role.mafiaGirl).firstOrNull;
    final normal = alive.where((p) => p.role == Role.normalMafia).firstOrNull;
    final killer = sheikh ?? girl ?? normal;
    if (killer != null) {
      final targets = alive
          .where((player) => player.role.team != Team.mafia)
          .map((player) => player.id)
          .toList();
      if (targets.isNotEmpty) {
        _addPrompt(
            prompts,
            killer.id,
            PlayerActionPrompt(
                type: 'assassination', availableTargets: targets));
      }
    }

    if (girl != null) {
      final previouslySilenced = state.eventHistory
          .where((event) =>
              event.type == EventType.silence && event.actorId == girl.id)
          .map((event) => event.targetId)
          .whereType<String>()
          .toSet();
      final targets =
          aliveIds.where((id) => !previouslySilenced.contains(id)).toList();
      if (targets.isNotEmpty) {
        _addPrompt(prompts, girl.id,
            PlayerActionPrompt(type: 'silence', availableTargets: targets));
      }
    }

    final citizenSheikh =
        alive.where((p) => p.role == Role.citizensSheikh).firstOrNull;
    if (citizenSheikh != null) {
      final targets = aliveIds.where((id) => id != citizenSheikh.id).toList();
      if (targets.isNotEmpty) {
        _addPrompt(
          prompts,
          citizenSheikh.id,
          PlayerActionPrompt(type: 'investigation', availableTargets: targets),
        );
      }
    }

    final citizenGirl =
        alive.where((p) => p.role == Role.citizensGirl).firstOrNull;
    if (citizenGirl != null) {
      final previouslyProtected = state.eventHistory
          .where((event) =>
              event.type == EventType.protection &&
              event.actorId == citizenGirl.id)
          .map((event) => event.targetId)
          .whereType<String>()
          .toSet();
      final targets =
          aliveIds.where((id) => !previouslyProtected.contains(id)).toList();
      if (targets.isNotEmpty) {
        _addPrompt(prompts, citizenGirl.id,
            PlayerActionPrompt(type: 'protection', availableTargets: targets));
      }
    }
    return prompts;
  }

  void _addPrompt(
    Map<String, List<PlayerActionPrompt>> prompts,
    String playerId,
    PlayerActionPrompt prompt,
  ) {
    (prompts[playerId] ??= <PlayerActionPrompt>[]).add(prompt);
  }

  Map<String, List<PlayerActionPrompt>> _retaliationPrompts(GameState state) {
    final actor = _citizenBoyActor(state);
    if (actor == null || state.alivePlayers.isEmpty) return {};
    return {
      actor.id: [
        PlayerActionPrompt(
          type: 'retaliation',
          availableTargets:
              state.alivePlayers.map((player) => player.id).toList(),
        ),
      ],
    };
  }

  Player? _citizenBoyActor(GameState state) {
    if (state.phase != Phase.triggeredAbility) return null;
    final lastSummary = state.eventHistory
        .where((event) => event.type == EventType.nightResolutionSummary)
        .lastOrNull;
    final lastElimination = state.eventHistory
        .where((event) => event.type == EventType.elimination)
        .lastOrNull;
    if (lastSummary != null &&
        (lastElimination == null ||
            lastSummary.timestamp.isAfter(lastElimination.timestamp))) {
      final deadIds =
          (lastSummary.metadata['assassinatedIds'] as List? ?? const [])
              .cast<String>()
              .toSet();
      return state.players
          .where((player) =>
              deadIds.contains(player.id) && player.role == Role.citizensBoy)
          .firstOrNull;
    }
    if (lastElimination == null) return null;
    final player = state.getPlayerById(lastElimination.targetId ?? '');
    return player?.role == Role.citizensBoy ? player : null;
  }

  Phase _nextPhaseAfterRetaliation(GameState state) {
    final latestResolution = state.eventHistory
        .where((event) => event.type == EventType.nightResolutionSummary)
        .lastOrNull;
    final latestElimination = state.eventHistory
        .where((event) => event.type == EventType.elimination)
        .lastOrNull;
    if (latestElimination != null &&
        (latestResolution == null ||
            latestElimination.timestamp.isAfter(latestResolution.timestamp))) {
      return Phase.night;
    }
    return Phase.day;
  }

  Future<void> _startNightActions() => _runHostAction(() async {
        final service = ref.read(interactiveServiceProvider);
        final orchestrator = ref.read(gameOrchestratorProvider.notifier);
        final before = ref.read(gameOrchestratorProvider);
        if (before.phase == Phase.elimination) {
          await service.clearActionRequests(widget.sessionId);
          orchestrator.advanceToNight();
        } else if (before.phase != Phase.night) {
          return;
        } else {
          final session = await service.getSession(widget.sessionId);
          if (session?.actionsPhase == Phase.night &&
              session?.actionsRound == before.round) {
            _nightActionRounds.add(before.round);
            return;
          }
          await service.clearActionRequests(widget.sessionId);
        }
        final state = ref.read(gameOrchestratorProvider);
        _nightActionRounds.add(state.round);
        await _syncStateToClients(
          actionPrompts: _nightPrompts(state),
          clearPrivateResults: true,
        );
      });

  Future<void> _resolveNight(
    List<InteractiveSeat> seats,
    List<ActionRequest> actions,
  ) =>
      _runHostAction(() async {
        final service = ref.read(interactiveServiceProvider);
        final orchestrator = ref.read(gameOrchestratorProvider.notifier);
        final stateBefore = ref.read(gameOrchestratorProvider);
        final expected = _nightPrompts(stateBefore);
        final used = <String>{};
        final privateResults = <String, String>{};

        for (final action in actions) {
          final seat = _seatForUid(seats, action.uid);
          if (seat == null || !seat.isAlive) continue;
          final prompt = expected[seat.id]
              ?.where((item) => item.type == action.actionType)
              .firstOrNull;
          if (prompt == null ||
              !prompt.availableTargets.contains(action.targetId) ||
              !used.add('${seat.id}:${action.actionType}')) {
            continue;
          }

          final type = switch (action.actionType) {
            'assassination' => EventType.assassination,
            'protection' => EventType.protection,
            'investigation' => EventType.investigation,
            'silence' => EventType.silence,
            _ => null,
          };
          if (type == null) continue;
          orchestrator.submitNightAction(
            actorId: seat.id,
            targetId: action.targetId,
            type: type,
          );
          if (action.actionType == 'investigation') {
            final target = stateBefore.getPlayerById(action.targetId);
            if (target != null) {
              privateResults[seat.id] =
                  'اللاعب ${target.name} ${target.role.team == Team.mafia ? 'من المافيا!' : 'من المواطنين'}';
            }
          }
        }

        await service.clearActionRequests(widget.sessionId);
        orchestrator.resolveNight();
        final state = ref.read(gameOrchestratorProvider);
        final prompts = state.phase == Phase.triggeredAbility
            ? _retaliationPrompts(state)
            : null;
        await _syncStateToClients(
          actionPrompts: prompts,
          privateResults: privateResults,
        );
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CinematicRevealScreen(
              interactiveSessionId: widget.sessionId,
              onInteractiveExit: _confirmEndSession,
            ),
          ),
        );
        if (mounted &&
            ref.read(gameOrchestratorProvider).phase == Phase.winCheck) {
          _openGameOver();
        }
      });

  Future<void> _resolveRetaliation(
    List<InteractiveSeat> seats,
    List<ActionRequest> actions,
  ) =>
      _runHostAction(() async {
        final state = ref.read(gameOrchestratorProvider);
        final actor = _citizenBoyActor(state);
        final nextPhase = _nextPhaseAfterRetaliation(state);
        if (actor == null) return;

        final valid = actions.where((action) {
          final seat = _seatForUid(seats, action.uid);
          return action.actionType == 'retaliation' &&
              seat?.id == actor.id &&
              state.alivePlayers.any((p) => p.id == action.targetId);
        }).firstOrNull;
        if (valid == null) return;
        final victim = state.getPlayerById(valid.targetId);
        if (victim == null) return;

        final service = ref.read(interactiveServiceProvider);
        await service.clearActionRequests(widget.sessionId);
        ref.read(gameOrchestratorProvider.notifier).citizenBoyRetaliation(
              actorId: actor.id,
              targetId: valid.targetId,
              nextPhase: nextPhase,
            );
        final after = ref.read(gameOrchestratorProvider);
        if (after.phase == Phase.night) {
          _nightActionRounds.add(after.round);
          await _syncStateToClients(
            actionPrompts: _nightPrompts(after),
            clearPrivateResults: true,
          );
        } else {
          await _syncStateToClients();
        }

        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => DramaticRevealDialog(
              quote: 'انتقام المواطن الشجاع كشف ضحيته... والحقيقة ستظهر الآن.',
              eliminated: victim,
              onContinue: () => Navigator.of(dialogContext).pop(),
            ),
          );
        }
        if (mounted && after.phase == Phase.winCheck) _openGameOver();
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

  void _openGameOver() {
    if (_isOpeningGameOver || !mounted) return;
    _isOpeningGameOver = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(interactiveSessionId: widget.sessionId),
      ),
    );
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
    final needNightPrompts = state.phase == Phase.night &&
        state.round > 1 &&
        !_nightActionRounds.contains(state.round);

    return Scaffold(
      
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
              final submitted = <String>{};
              for (final action in actions) {
                final seat = _seatForUid(seats, action.uid);
                if (seat != null)
                  submitted.add('${seat.id}:${action.actionType}');
              }
              final retaliationActor = _citizenBoyActor(state);
              final hasRetaliation = retaliationActor != null &&
                  submitted.contains('${retaliationActor.id}:retaliation');
              final nightPrompts = _nightPrompts(state);
              final expectedNightActions = nightPrompts.entries
                  .expand((entry) => entry.value
                      .map((prompt) => '${entry.key}:${prompt.type}'))
                  .toList();
              final nightReady = expectedNightActions
                  .every((actionKey) => submitted.contains(actionKey));

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
                        itemCount: state.players.length,
                        itemBuilder: (context, index) {
                          final player = state.players[index];
                          final isAlive = player.isAlive;
                          final assigned = state.phase == Phase.night
                              ? nightPrompts[player.id] ?? const []
                              : state.phase == Phase.triggeredAbility &&
                                      player.id == retaliationActor?.id
                                  ? const [
                                      PlayerActionPrompt(
                                        type: 'retaliation',
                                        availableTargets: [],
                                      ),
                                    ]
                                  : const <PlayerActionPrompt>[];
                          final allSubmitted = assigned.isNotEmpty &&
                              assigned.every((prompt) => submitted
                                  .contains('${player.id}:${prompt.type}'));
                          return ListTile(
                            title: Text(
                              player.name,
                              style: TextStyle(
                                color: isAlive ? Colors.white : Colors.white38,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            subtitle: Text(
                              isAlive
                                  ? 'على قيد اللعبة'
                                  : 'تمت تصفيته • ${player.role.name}',
                              style: TextStyle(
                                color: isAlive
                                    ? Colors.white38
                                    : Colors.orangeAccent,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            trailing: assigned.isEmpty
                                ? const Icon(Icons.nightlight_round,
                                    color: Colors.blueGrey)
                                : Icon(
                                    allSubmitted
                                        ? Icons.check_circle
                                        : Icons.hourglass_empty,
                                    color: allSubmitted
                                        ? Colors.greenAccent
                                        : Colors.grey,
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.phase == Phase.roleReveal)
                      _phaseButton(
                        label: 'انتهى كشف الأدوار — ابدأ ليلة التعارف',
                        onPressed: _beginIntroductionNight,
                      ),
                    if (state.phase == Phase.day)
                      _phaseButton(
                        label: 'ابدأ النهار والنقاش',
                        onPressed: _openDayDiscussion,
                      ),
                    if (state.phase == Phase.voting)
                      _phaseButton(
                        label: 'العودة إلى قاعة المحكمة',
                        onPressed: _resumeVotingCourt,
                      ),
                    if (state.phase == Phase.elimination)
                      _phaseButton(
                        label: 'متابعة إلى الليل',
                        onPressed: _startNightActions,
                      ),
                    if (state.phase == Phase.night && needNightPrompts)
                      _phaseButton(
                        label: 'نشر إجراءات الليل للاعبين',
                        enabled: !_isLoadingSessionState,
                        onPressed: _startNightActions,
                      ),
                    if (state.phase == Phase.night && !needNightPrompts)
                      _phaseButton(
                        label: 'إنهاء الليل وعرض النتيجة',
                        enabled: nightReady,
                        onPressed: () => _resolveNight(seats, actions),
                      ),
                    if (state.phase == Phase.triggeredAbility)
                      _phaseButton(
                        label: 'تأكيد الانتقام ومتابعة اللعبة',
                        enabled: hasRetaliation,
                        onPressed: () => _resolveRetaliation(seats, actions),
                      ),
                    if (state.phase == Phase.winCheck)
                      _phaseButton(
                        label: 'عرض النتيجة والجريدة والإحصائيات',
                        onPressed: () async => _openGameOver(),
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
