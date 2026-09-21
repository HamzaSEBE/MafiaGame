import 'package:flutter/material.dart';
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

class VotingScreen extends ConsumerStatefulWidget {
  const VotingScreen({super.key});

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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text('┘ä┘à┘å ╪│┘è╪╡┘ê╪¬ ${voter.name}╪ƒ', style: const TextStyle(fontSize: 20, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
              ],
            ),
            const SizedBox(height: 16),
            ..._alive.where((p) => p.id != voter.id).map((candidate) => ListTile(
                  title: Text(candidate.name, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold)),
                  trailing: _votes[voter.id] == candidate.id ? const Icon(Icons.check_circle, color: Colors.orangeAccent) : null,
                  onTap: () {
                    setState(() => _votes[voter.id] = candidate.id);
                    ref.read(audioManagerProvider).playVote();
                    Navigator.pop(ctx);
                  },
                )),
            ListTile(
              title: const Text('╪Ñ┘ä╪║╪º╪í ╪º┘ä╪¬╪╡┘ê┘è╪¬', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo', fontSize: 16)),
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

  void _confirmExecution() {
    ref.read(gameOrchestratorProvider.notifier).submitFinalVotes(_votes);
    final result = ref.read(gameOrchestratorProvider.notifier).resolveVote();
    
    if (result['isTie'] == true) {
      _showTieDialog(result['tiedPlayers']);
    } else if (result['eliminatedId'] != null) {
      _showExecutionDialog(result['eliminatedId']);
    } else {
      _showNoEliminationDialog();
    }
  }

  void _showTieDialog(List<dynamic>? tiedIds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.orangeAccent, width: 2)),
        title: const Text('╪¬╪╣╪º╪»┘ä ┘ü┘è ╪º┘ä╪¬╪╡┘ê┘è╪¬!', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text(
          '╪¬╪╣╪º╪»┘ä ╪º┘ä╪ú╪┤╪«╪º╪╡ ┘ü┘è ╪º┘ä╪ú╪╡┘ê╪º╪¬. ┘ç┘ä ╪¬╪▒┘è╪» ╪Ñ╪╣╪º╪»╪⌐ ╪º┘ä╪¬╪╡┘ê┘è╪¬ ╪ú┘à ╪Ñ┘å┘ç╪º╪í ╪º┘ä┘å┘ç╪º╪▒ ╪¿┘ä╪º ╪Ñ╪╣╪»╪º┘à╪ƒ',
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _votes.clear());
              ref.read(gameOrchestratorProvider.notifier).revote();
            },
            child: const Text('╪Ñ╪╣╪º╪»╪⌐ ╪º┘ä╪¬╪╡┘ê┘è╪¬', style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _transitionToNextPhase(null);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('╪Ñ┘å┘ç╪º╪í ╪¿╪»┘ê┘å ╪Ñ╪╣╪»╪º┘à', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  void _showNoEliminationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('┘ä╪º ╪Ñ╪╣╪»╪º┘à', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text(
          '┘ä┘à ┘è╪¬┘à ╪º┘ä╪¬╪╡┘ê┘è╪¬ ╪╢╪» ╪ú╪¡╪». ┘ç┘ä ╪¬╪▒┘è╪» ╪Ñ┘å┘ç╪º╪í ╪º┘ä┘å┘ç╪º╪▒╪ƒ',
          style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _votes.clear());
              ref.read(gameOrchestratorProvider.notifier).revote();
            },
            child: const Text('╪▒╪¼┘ê╪╣ ┘ä┘ä╪¬╪╡┘ê┘è╪¬', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _transitionToNextPhase(null);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('╪Ñ┘å┘ç╪º╪í ╪º┘ä┘å┘ç╪º╪▒', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExecutionDialog(String eliminatedId) {
    final executedPlayer = ref.read(gameOrchestratorProvider).getPlayerById(eliminatedId);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 2)),
        title: const Text('╪¬╪ú┘â┘è╪» ╪º┘ä╪Ñ╪╣╪»╪º┘à', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(
          '╪¬┘à ╪º╪«╪¬┘è╪º╪▒ ${executedPlayer?.name} ┘ä┘ä╪Ñ╪╣╪»╪º┘à. ┘ç┘ä ╪¬╪▒╪║╪¿ ┘ü┘è ┘à┘å╪¡┘ç 40 ╪½╪º┘å┘è╪⌐ ┘ä┘ä╪»┘ü╪º╪╣ ╪╣┘å ┘å┘ü╪│┘ç╪ƒ',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _votes.clear());
              ref.read(gameOrchestratorProvider.notifier).revote();
            },
            child: const Text('╪¬╪║┘è┘è╪▒ ╪º┘ä╪¬╪╡┘ê┘è╪¬', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showDefenseTimer(executedPlayer, eliminatedId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('┘ê┘é╪¬ ╪º┘ä╪»┘ü╪º╪╣', style: TextStyle(color: Colors.black, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _transitionToNextPhase(eliminatedId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('╪Ñ╪╣╪»╪º┘à ┘ü┘ê╪▒┘è', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDefenseTimer(Player? executedPlayer, String eliminatedId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DefenseTimerDialog(
        accused: executedPlayer,
        onConfirmElimination: () {
          Navigator.pop(ctx);
          _transitionToNextPhase(eliminatedId);
        },
        onChangeVotes: () {
          Navigator.pop(ctx);
          setState(() => _votes.clear());
          ref.read(gameOrchestratorProvider.notifier).revote();
        },
      ),
    );
  }

  void _transitionToNextPhase(String? eliminatedId) {
    final state = ref.read(gameOrchestratorProvider);
    if (state.phase == Phase.winCheck) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameOverScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NightScreen()));
    }
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('╪Ñ┘å┘ç╪º╪í ╪º┘ä┘ä╪╣╪¿╪⌐╪ƒ', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo')),
        content: const Text('┘ç┘ä ╪ú┘å╪¬ ┘à╪¬╪ú┘â╪» ╪ú┘å┘â ╪¬╪▒┘è╪» ╪Ñ┘å┘ç╪º╪í ╪º┘ä┘ä╪╣╪¿╪⌐ ┘ê╪º┘ä╪╣┘ê╪»╪⌐ ┘ä┘ä╪▒╪ª┘è╪│┘è╪⌐╪ƒ', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('╪Ñ┘ä╪║╪º╪í', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
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
            child: const Text('┘å╪╣┘à╪î ╪Ñ┘å┘ç╪º╪í', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GamePopScope(
      child: Scaffold(
        backgroundColor: const Color(0xFF07070B),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('┘é╪º╪╣╪⌐ ╪º┘ä┘à╪¡┘â┘à╪⌐', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              onPressed: () => _confirmExit(context, ref),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: [Color(0xFF261D15), Color(0xFF130E0A), Color(0xFF07070B)])))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.gavel, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text('╪¡╪º┘å ┘ê┘é╪¬ ╪º┘ä╪¬╪╡┘ê┘è╪¬', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                    const Text('╪º╪╢╪║╪╖ ╪╣┘ä┘ë ╪º╪│┘à ┘â┘ä ┘ä╪º╪╣╪¿ ┘ä╪º╪«╪¬┘è╪º╪▒ ┘à┘å ╪│┘è╪╡┘ê╪¬ ╪╢╪»┘ç', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _alive.length,
                        itemBuilder: (context, index) {
                          final voter = _alive[index];
                          final votedId = _votes[voter.id];
                          final votedPlayer = votedId != null ? ref.read(gameOrchestratorProvider).getPlayerById(votedId) : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: votedPlayer != null ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(voter.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                              subtitle: Text(votedPlayer != null ? '┘è╪╡┘ê╪¬ ╪╢╪»: ${votedPlayer.name}' : '┘ä┘à ┘è╪╡┘ê╪¬', style: TextStyle(color: votedPlayer != null ? Colors.redAccent : Colors.white54, fontFamily: 'Cairo')),
                              trailing: Icon(Icons.touch_app, color: Colors.white.withValues(alpha: 0.3)),
                              onTap: () => _showVotePicker(voter),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _confirmExecution,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          elevation: 10,
                          shadowColor: Colors.redAccent.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('╪Ñ┘å┘ç╪º╪í ╪º┘ä╪¬╪╡┘ê┘è╪¬', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
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

class _DefenseTimerDialog extends ConsumerStatefulWidget {
  final Player? accused;
  final VoidCallback onConfirmElimination;
  final VoidCallback onChangeVotes;

  const _DefenseTimerDialog({
    required this.accused,
    required this.onConfirmElimination,
    required this.onChangeVotes,
  });

  @override
  ConsumerState<_DefenseTimerDialog> createState() => _DefenseTimerDialogState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 2)),
      title: const Text('┘à╪¡╪º┘â┘à╪⌐ ╪º┘ä┘à╪º┘ü┘è╪º!', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.accused?.name ?? '╪ƒ',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            '$_secondsLeft',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _secondsLeft <= 10 ? Colors.redAccent : Colors.greenAccent,
            ),
          ),
          const Text('┘ä╪»┘è┘â 40 ╪½╪º┘å┘è╪⌐ ┘ä┘ä╪»┘ü╪º╪╣ ╪╣┘å ┘å┘ü╪│┘â', style: TextStyle(fontFamily: 'Cairo', color: Colors.white54)),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        if (_secondsLeft > 0 && !_isRunning)
          ElevatedButton(
            onPressed: _startTimer,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, minimumSize: const Size(double.infinity, 48)),
            child: const Text('╪º╪¿╪»╪ú ╪º┘ä┘ê┘é╪¬', style: TextStyle(fontFamily: 'Cairo', color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 12),
        const Text('╪¿╪╣╪» ╪º┘å╪¬┘ç╪º╪í ╪º┘ä╪»┘ü╪º╪╣:', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onChangeVotes,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('╪¬╪║┘è┘è╪▒ ╪º┘ä╪¬╪╡┘ê┘è╪¬', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onConfirmElimination,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('╪¬╪ú┘â┘è╪» ╪º┘ä╪Ñ╪╣╪»╪º┘à', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
