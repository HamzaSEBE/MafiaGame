import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/game_over/game_over_screen.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';
import 'dart:async';
import 'package:mafia_nightfall/core/quotes/dramatic_quotes.dart';
import 'package:mafia_nightfall/presentation/widgets/judge_tools_sheet.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/domain/entities/game_state.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';

class VotingScreen extends ConsumerStatefulWidget {
  final String? interactiveSessionId;
  final Future<void> Function()? onInteractiveExit;

  const VotingScreen({
    super.key,
    this.interactiveSessionId,
    this.onInteractiveExit,
  });

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  final Map<String, String> _votes = {};

  List<Player> get _alive => ref.read(gameOrchestratorProvider).alivePlayers;

  void _showVotePicker(Player voter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text('لمن سيصوت ${voter.name}؟',
                    style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent)),
              ],
            ),
            const SizedBox(height: 16),
            ..._alive
                .where((p) => p.id != voter.id)
                .map((candidate) => ListTile(
                      title: Text(candidate.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      trailing: _votes[voter.id] == candidate.id
                          ? const Icon(Icons.check_circle,
                              color: Colors.orangeAccent)
                          : null,
                      onTap: () {
                        setState(() => _votes[voter.id] = candidate.id);
                        ref.read(audioManagerProvider).playVote();
                        Navigator.pop(ctx);
                      },
                    )),
            ListTile(
              title: const Text('إلغاء التصويت',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'Cairo',
                      fontSize: 16)),
              leading: const Icon(Icons.cancel, color: Colors.redAccent),
              onTap: () {
                setState(() => _votes.remove(voter.id));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _calculateResult(Map<String, String> votes) {
    if (votes.isEmpty) {
      if (widget.interactiveSessionId != null) {
        _skipInteractiveVote();
        return;
      }
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('لم يصوت أحد!',
              style: TextStyle(
                  color: Colors.orangeAccent,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold)),
          content: const Text(
              'هل أنت متأكد من إنهاء التصويت بدون إقصاء أي لاعب والانتقال لليل؟',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(gameOrchestratorProvider.notifier).skipElimination();
                _goToNight();
              },
              child: const Text('نعم، انتقال',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final voteCounts = <String, int>{};
    for (var target in votes.values) {
      voteCounts[target] = (voteCounts[target] ?? 0) + 1;
    }

    int maxVotes = voteCounts.values.reduce((a, b) => a > b ? a : b);
    final topCandidates = voteCounts.entries
        .where((e) => e.value == maxVotes)
        .map((e) => e.key)
        .toList();

    if (topCandidates.length > 1) {
      _showTieDialog(topCandidates);
    } else {
      _showDefenseDialog(topCandidates.first, maxVotes, votes);
    }
  }

  void _showTieDialog(List<String> tiedIds) {
    final state = ref.read(gameOrchestratorProvider);
    final names =
        tiedIds.map((id) => state.getPlayerById(id)?.name ?? id).join(' و ');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.balance, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('تعادل!',
                style: TextStyle(
                    color: Colors.orangeAccent,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('تعادل بين: $names\nماذا تريد أن تفعل؟',
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.interactiveSessionId != null) {
                _skipInteractiveVote();
              } else {
                ref.read(gameOrchestratorProvider.notifier).skipElimination();
                _goToNight();
              }
            },
            child: const Text('تخطي الإقصاء',
                style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.interactiveSessionId != null) {
                _prepareInteractiveRevote();
              } else {
                ref.read(gameOrchestratorProvider.notifier).revote();
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('إعادة التصويت',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDefenseDialog(
    String accusedId,
    int votesCount,
    Map<String, String> votes,
  ) {
    final state = ref.read(gameOrchestratorProvider);
    final accused = state.getPlayerById(accusedId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DefenseTimerDialog(
        accused: accused,
        votesCount: votesCount,
        onConfirmElimination: () {
          ref.read(audioManagerProvider).playClick();
          ref.read(audioManagerProvider).playKill();
          Navigator.pop(ctx);
          ref.read(gameOrchestratorProvider.notifier).submitFinalVotes(votes);
          ref.read(gameOrchestratorProvider.notifier).resolveVote();
          _afterDefense(accusedId);
        },
        onChangeVotes: () {
          Navigator.pop(ctx);
          if (widget.interactiveSessionId != null) {
            _prepareInteractiveRevote();
          } else {
            ref.read(gameOrchestratorProvider.notifier).revote();
          }
        },
      ),
    );
  }

  Future<void> _afterDefense(String accusedId) async {
    final sessionId = widget.interactiveSessionId;
    final state = ref.read(gameOrchestratorProvider);
    if (sessionId == null) {
      _handleElimination(accusedId);
      return;
    }

    final service = ref.read(interactiveServiceProvider);
    await service.clearActionRequests(sessionId);
    await service.syncGameState(
      sessionId,
      state,
      null,
      null,
      actionPrompts: state.phase == Phase.triggeredAbility
          ? _retaliationPrompts(state)
          : null,
    );
    if (!mounted) return;
    _handleElimination(accusedId);
  }

  Map<String, List<PlayerActionPrompt>> _retaliationPrompts(GameState state) {
    final elimination = state.eventHistory
        .where((event) => event.type == EventType.elimination)
        .lastOrNull;
    final actor = elimination == null
        ? null
        : state.getPlayerById(elimination.targetId ?? '');
    if (actor?.role != Role.citizensBoy || state.alivePlayers.isEmpty) {
      return {};
    }
    return {
      actor!.id: [
        PlayerActionPrompt(
          type: 'retaliation',
          availableTargets:
              state.alivePlayers.map((player) => player.id).toList(),
        ),
      ],
    };
  }

  Future<void> _prepareInteractiveRevote() async {
    final sessionId = widget.interactiveSessionId;
    if (sessionId == null) return;
    final service = ref.read(interactiveServiceProvider);
    ref.read(gameOrchestratorProvider.notifier).revote();
    final state = ref.read(gameOrchestratorProvider);
    final aliveIds = state.alivePlayers.map((player) => player.id).toList();
    final prompts = <String, List<PlayerActionPrompt>>{};
    for (final player in state.alivePlayers) {
      final targets = aliveIds.where((id) => id != player.id).toList();
      if (targets.isNotEmpty) {
        prompts[player.id] = [
          PlayerActionPrompt(type: 'vote', availableTargets: targets),
        ];
      }
    }
    await service.syncGameState(
      sessionId,
      state,
      null,
      null,
      actionPrompts: prompts,
    );
  }

  Future<void> _skipInteractiveVote() async {
    final sessionId = widget.interactiveSessionId;
    if (sessionId == null) return;
    final service = ref.read(interactiveServiceProvider);
    await service.clearActionRequests(sessionId);
    ref.read(gameOrchestratorProvider.notifier).skipElimination();
    await service.syncGameState(
      sessionId,
      ref.read(gameOrchestratorProvider),
      null,
      null,
      actionPrompts: const {},
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _handleElimination(String? eliminatedId) {
    final state = ref.read(gameOrchestratorProvider);

    if (state.phase == Phase.winCheck) {
      if (widget.interactiveSessionId != null && eliminatedId != null) {
        final eliminated = state.getPlayerById(eliminatedId);
        if (eliminated != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => DramaticRevealDialog(
              quote: DramaticQuotes.getRandomDayElimination(),
              eliminated: eliminated,
              onContinue: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
            ),
          );
          return;
        }
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GameOverScreen()),
        (route) => false,
      );
      return;
    }

    if (eliminatedId != null) {
      final eliminated = state.getPlayerById(eliminatedId);
      // Show dramatic suspense first
      final quote = DramaticQuotes.getRandomDayElimination();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => DramaticRevealDialog(
          quote: quote,
          eliminated: eliminated!,
          onContinue: () {
            Navigator.pop(ctx);
            if (widget.interactiveSessionId != null) {
              Navigator.of(context).pop();
            } else if (eliminated.role == Role.citizensBoy) {
              _showCitizenBoyDialog(eliminatedId);
            } else {
              _goToNight();
            }
          },
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
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.orangeAccent)),
          title: const Row(
            children: [
              Icon(Icons.bolt, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('انتقام المواطن الشجاع!',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('بما أنك قُتلت، يمكنك اختيار لاعب لتأخذه معك كضحية:',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
              const SizedBox(height: 16),
              ...alive.map((p) => RadioListTile<String>(
                    title: Text(p.name,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    value: p.id,
                    groupValue: selectedId,
                    activeColor: Colors.orangeAccent,
                    onChanged: (val) => setDialogState(() => selectedId = val),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(gameOrchestratorProvider.notifier).advanceToNight();
                _routeAfterRetaliation();
              },
              child: const Text('تخطي',
                  style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () {
                      ref.read(audioManagerProvider).playKill();
                      final targetPlayer = state.getPlayerById(selectedId!);
                      ref
                          .read(gameOrchestratorProvider.notifier)
                          .citizenBoyRetaliation(
                              actorId: actorId,
                              targetId: selectedId!,
                              nextPhase: Phase.night);
                      Navigator.pop(ctx);
                      _showRetaliationResultDialog(targetPlayer!);
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('انتقام!',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NightScreen()),
        (route) => false,
      );
    }
  }

  void _showRetaliationResultDialog(Player target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.roleColor(target.role), width: 2)),
        title: const Text('ضحية المواطن الشجاع!',
            style: TextStyle(
                color: Colors.redAccent,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.roleColor(target.role), width: 3),
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
            Text(target.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Text('كان: ${AppTheme.roleArabicName(target.role)}',
                style: TextStyle(
                    color: AppTheme.roleColor(target.role),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('متابعة',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _goToNight() {
    if (ref.read(gameOrchestratorProvider).phase != Phase.night) {
      ref.read(gameOrchestratorProvider.notifier).advanceToNight();
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const NightScreen()),
      (route) => false,
    );
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    if (widget.onInteractiveExit != null) {
      widget.onInteractiveExit!();
      return;
    }
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
    final alive = _alive;
    if (alive.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (widget.interactiveSessionId != null) {
      final service = ref.read(interactiveServiceProvider);
      return StreamBuilder<List<InteractiveSeat>>(
        stream: service.streamSeats(widget.interactiveSessionId!),
        builder: (context, seatSnap) {
          if (seatSnap.hasError)
            return _remoteError('تعذر تحميل المقاعد: ${seatSnap.error}');
          if (!seatSnap.hasData) {
            return const Scaffold(
                body: Center(
                    child:
                        CircularProgressIndicator(color: Colors.orangeAccent)));
          }
          return StreamBuilder<List<ActionRequest>>(
            stream: service.streamActionRequests(widget.interactiveSessionId!),
            builder: (context, actionSnap) {
              if (actionSnap.hasError)
                return _remoteError('تعذر تحميل الأصوات: ${actionSnap.error}');
              final seats = seatSnap.data!;
              final actions = actionSnap.data ?? const <ActionRequest>[];
              final votes = <String, String>{};
              final submittedVoters = <String>{};
              final aliveIds = alive.map((player) => player.id).toSet();
              final latestVoteByUid = <String, ActionRequest>{};
              for (final action
                  in actions.where((item) => item.actionType == 'vote')) {
                final seat = seats
                    .where((item) => item.linkedUid == action.uid)
                    .firstOrNull;
                if (seat != null &&
                    aliveIds.contains(seat.id) &&
                    aliveIds.contains(action.targetId) &&
                    seat.id != action.targetId) {
                  final previous = latestVoteByUid[action.uid];
                  if (previous == null ||
                      action.revision > previous.revision ||
                      (action.revision == previous.revision &&
                          !action.timestamp.isBefore(previous.timestamp))) {
                    latestVoteByUid[action.uid] = action;
                  }
                }
              }
              for (final entry in latestVoteByUid.entries) {
                final seat = seats
                    .where((item) => item.linkedUid == entry.key)
                    .firstOrNull;
                if (seat != null) {
                  votes[seat.id] = entry.value.targetId;
                  submittedVoters.add(seat.id);
                }
              }
              return _buildCourt(votes,
                  remote: true, submittedVoters: submittedVoters);
            },
          );
        },
      );
    }

    return _buildCourt(_votes);
  }

  Widget _buildCourt(
    Map<String, String> votes, {
    bool remote = false,
    Set<String> submittedVoters = const {},
  }) {
    final alive = _alive;

    // Calculate votes for each candidate for the badges
    final voteCounts = <String, int>{};
    for (var target in votes.values) {
      voteCounts[target] = (voteCounts[target] ?? 0) + 1;
    }

    return GamePopScope(
      onExit: widget.onInteractiveExit,
      child: Scaffold(
        
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('قاعة المحكمة',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo')),
          actions: [
            IconButton(
              icon: const Icon(Icons.handyman, color: Colors.blueAccent),
              tooltip: 'أدوات الحكم',
              onPressed: () => JudgeToolsSheet.show(context),
            ),
            TextButton(
              onPressed: () {
                if (remote) {
                  _skipInteractiveVote();
                } else {
                  ref.read(gameOrchestratorProvider.notifier).skipElimination();
                  _goToNight();
                }
              },
              child: const Text('تخطي التصويت',
                  style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold)),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              blurRadius: 30)
                        ],
                      ),
                      child: const Icon(Icons.gavel,
                          size: 48, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    const Text('⚖️ قاعة المحاكمة',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Cairo')),
                    const Text('اضغط على اسم اللاعب لاختيار من سيصوت ضده',
                        style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Cairo',
                            fontSize: 13)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: alive.length,
                        itemBuilder: (context, index) {
                          final voter = alive[index];
                          final votedId = votes[voter.id];
                          final votedPlayer = votedId != null
                              ? ref
                                  .read(gameOrchestratorProvider)
                                  .getPlayerById(votedId)
                              : null;
                          final votesReceived = voteCounts[voter.id] ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: votedPlayer != null
                                      ? Colors.orangeAccent.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              title: Row(
                                children: [
                                  Text(voter.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Cairo')),
                                  if (voter.isCitizenSheikhRevealed) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('x3', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (votesReceived > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.redAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border:
                                            Border.all(color: Colors.redAccent),
                                      ),
                                      child: Text('$votesReceived صوت',
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                  votedPlayer != null
                                      ? 'يصوت ضد: ${votedPlayer.name}'
                                      : 'لم يصوت بعد',
                                  style: TextStyle(
                                      color: votedPlayer != null
                                          ? Colors.redAccent
                                          : Colors.white54,
                                      fontFamily: 'Cairo')),
                              trailing: remote
                                  ? Icon(
                                      submittedVoters.contains(voter.id)
                                          ? Icons.check_circle
                                          : Icons.hourglass_empty,
                                      color: submittedVoters.contains(voter.id)
                                          ? Colors.greenAccent
                                          : Colors.white38,
                                    )
                                  : Icon(Icons.touch_app,
                                      color: Colors.white.withOpacity(0.3)),
                              onTap:
                                  remote ? null : () => _showVotePicker(voter),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _calculateResult(votes),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          elevation: 10,
                          shadowColor: Colors.redAccent.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          remote
                              ? 'فرز الأصوات (${submittedVoters.length}/${alive.length})'
                              : 'فرز الأصوات',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Cairo'),
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

  Widget _remoteError(String message) => Scaffold(
        
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.redAccent, fontFamily: 'Cairo')),
          ),
        ),
      );
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
  ConsumerState<_DefenseTimerDialog> createState() =>
      _DefenseTimerDialogState();
}

class _DefenseTimerDialogState extends ConsumerState<_DefenseTimerDialog> {
  int _secondsLeft = 40;
  bool _isRunning = false;

  void _startTimer() async {
    setState(() => _isRunning = true);
    ref.read(audioManagerProvider).playClick();
    while (_secondsLeft > 0 && _isRunning) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRunning) return;
      setState(() => _secondsLeft--);
    }
    if (_secondsLeft == 0 && mounted) {
      setState(() => _isRunning = false);
      ref.read(audioManagerProvider).playClick();
    }
  }

  @override
  void dispose() {
    _isRunning = false;
    ref.read(audioManagerProvider).playClick();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canJudgeDuringDefense = _isRunning || _secondsLeft == 0;
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 2)),
      title: const Text('محاكمة المافيا!',
          style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo'),
          textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.accused?.name ?? '؟',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text('حصل على ${widget.votesCount} أصوات',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, fontFamily: 'Cairo')),
          const SizedBox(height: 24),
          Text(
            '$_secondsLeft',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _secondsLeft <= 10 ? Colors.redAccent : Colors.greenAccent,
            ),
          ),
          const Text('لديك 40 ثانية للدفاع عن نفسك',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white54)),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        if (_secondsLeft > 0 && !_isRunning)
          ElevatedButton(
            onPressed: _startTimer,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                minimumSize: const Size(double.infinity, 48)),
            child: const Text('ابدأ الوقت',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 12),
        const Text('أثناء وقت الدفاع يمكن للحكم تأكيد القرار أو تغييره:',
            style: TextStyle(
                color: Colors.white54, fontSize: 12, fontFamily: 'Cairo')),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: canJudgeDuringDefense ? widget.onChangeVotes : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('تغيير التصويت',
                    style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    canJudgeDuringDefense ? widget.onConfirmElimination : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('تأكيد الإعدام',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DramaticRevealDialog extends StatefulWidget {
  final String quote;
  final Player eliminated;
  final VoidCallback onContinue;

  const DramaticRevealDialog({
    super.key,
    required this.quote,
    required this.eliminated,
    required this.onContinue,
  });

  @override
  State<DramaticRevealDialog> createState() => DramaticRevealDialogState();
}

class DramaticRevealDialogState extends State<DramaticRevealDialog>
    with SingleTickerProviderStateMixin {
  bool _showQuote = true;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _showQuote = false);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.eliminated;
    final roleColor = AppTheme.roleColor(p.role);

    if (_showQuote) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (ctx, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              Text(
                widget.quote,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  shadows: [Shadow(color: Colors.redAccent, blurRadius: 30)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: roleColor, width: 2)),
          title: const Text('💀 الهوية الحقيقية',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: roleColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: roleColor.withValues(alpha: 0.5), blurRadius: 20)
                  ],
                ),
                child: ClipOval(
                    child: Image.asset(AppTheme.roleImage(p.role),
                        width: 90, height: 90, fit: BoxFit.cover)),
              ),
              const SizedBox(height: 16),
              Text(p.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                ),
                child: Text('كان: ${AppTheme.roleArabicName(p.role)}',
                    style: TextStyle(
                        color: roleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: roleColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('متابعة',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
