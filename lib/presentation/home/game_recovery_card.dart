import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_recovery.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_dashboard_screen.dart';
import 'package:mafia_nightfall/presentation/interactive/judge_lobby_screen.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';
import 'package:mafia_nightfall/domain/entities/interactive/models.dart';
import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';
import 'package:mafia_nightfall/presentation/reveal/role_reveal_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_screen.dart';
import 'package:mafia_nightfall/presentation/night/night_summary_screen.dart';
import 'package:mafia_nightfall/presentation/day/day_screen.dart';
import 'package:mafia_nightfall/presentation/voting/voting_screen.dart';

class GameRecoveryCard extends ConsumerWidget {
  const GameRecoveryCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recovery = ref.watch(gameRecoveryProvider);
    final writeError = ref.watch(checkpointErrorProvider);
    return Column(
      children: [
        if (writeError != null)
          const Text(
            'تعذر حفظ آخر تغيير على هذا الجهاز.',
            style: TextStyle(color: Colors.redAccent),
          ),
        recovery.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => TextButton(
            onPressed: () => ref.invalidate(gameRecoveryProvider),
            child: const Text('تعذر البحث عن لعبة محفوظة · أعد المحاولة'),
          ),
          data: (game) => game == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: Text(
                      game.sessionId == null
                          ? 'متابعة اللعبة · الجولة ${game.state.round}'
                          : 'متابعة الجلسة على هذا الجهاز · الجولة ${game.state.round}',
                    ),
                    onPressed: () async {
                      try {
                        var state = game.state;
                        Widget destination;
                        if (game.sessionId != null) {
                          final service = ref.read(interactiveServiceProvider);
                          final restored = await service.restoreCheckpoint(
                            game.sessionId!,
                            takeOver: true,
                          );
                          if (restored == null) {
                            ref.invalidate(gameRecoveryProvider);
                            return;
                          }
                          state = restored;
                          final session = await service.getSession(
                            game.sessionId!,
                          );
                          destination = session?.status == SessionStatus.waiting
                              ? const JudgeLobbyScreen()
                              : JudgeDashboardScreen(
                                  sessionId: game.sessionId!,
                                );
                        } else {
                          destination = switch (state.phase) {
                            Phase.setup => const SetupScreen(
                              isInteractive: false,
                            ),
                            Phase.roleReveal ||
                            Phase.mafiaReveal => const RoleRevealScreen(),
                            Phase.day => const DayScreen(),
                            Phase.voting ||
                            Phase.voteResolution ||
                            Phase.elimination => const VotingScreen(),
                            Phase.night ||
                            Phase.nightMafiaSheikh ||
                            Phase.nightMafiaGirl ||
                            Phase.nightNormalMafia ||
                            Phase.nightCitizensSheikh ||
                            Phase.nightCitizensGirl => const NightScreen(),
                            _ => const NightSummaryScreen(),
                          };
                        }
                        ref
                            .read(gameOrchestratorProvider.notifier)
                            .restoreCheckpoint(state);
                        if (!context.mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => destination),
                        );
                        ref.invalidate(gameRecoveryProvider);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تعذر استعادة اللعبة. أعد المحاولة.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
