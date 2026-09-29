import 'dart:io';

void main() {
  final file = File('lib/presentation/voting/voting_screen.dart');
  var content = """
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
                Text('لمن سيصوت \${voter.name}؟', style: const TextStyle(fontSize: 20, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
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
              title: const Text('إلغاء التصويت', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo', fontSize: 16)),
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
    final Map<String, int> counts = {};
    for (final candidateId in _votes.values) {
      counts[candidateId] = (counts[candidateId] ?? 0) + 1;
    }
    
    if (counts.isEmpty) {
      _showExecutionDialog(null);
      return;
    }
    
    int maxVotes = 0;
    String? executedId;
    bool tie = false;

    counts.forEach((id, count) {
      if (count > maxVotes) {
        maxVotes = count;
        executedId = id;
        tie = false;
      } else if (count == maxVotes) {
        tie = true;
      }
    });

    _showExecutionDialog(tie ? null : executedId);
  }

  void _showExecutionDialog(String? executedId) {
    final executedPlayer = executedId != null ? ref.read(gameOrchestratorProvider).getPlayerById(executedId) : null;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 2)),
        title: const Text('تأكيد الإعدام', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(
          executedPlayer != null 
              ? 'هل أنت متأكد من إعدام \${executedPlayer.name}؟'
              : 'لم يتم الاتفاق على شخص واحد (تعادل أو لا يوجد تصويت). هل تريد إنهاء النهار دون إعدام؟',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameOrchestratorProvider.notifier).resolveDay(executedId: executedId);
              
              final state = ref.read(gameOrchestratorProvider);
              if (state.phase == Phase.winCheck) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameOverScreen()));
              } else if (state.phase == Phase.night) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NightScreen()));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(executedPlayer != null ? 'تأكيد' : 'تخطي الإعدام', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إنهاء اللعبة؟', style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
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
            child: const Text('نعم، إنهاء', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
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
          title: const Text('قاعة المحكمة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
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
                    const Text('حان وقت التصويت', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                    const Text('اضغط على اسم كل لاعب لاختيار من سيصوت ضده', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
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
                              subtitle: Text(votedPlayer != null ? 'يصوت ضد: \${votedPlayer.name}' : 'لم يصوت', style: TextStyle(color: votedPlayer != null ? Colors.redAccent : Colors.white54, fontFamily: 'Cairo')),
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
                        child: const Text('تأكيد الإعدام وإنهاء النهار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
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
""";
  file.writeAsStringSync(content);
}