import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/role.dart';
import 'package:mafia_nightfall/domain/entities/player.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

import 'package:mafia_nightfall/data/repositories/history_repository.dart';
import 'package:mafia_nightfall/data/repositories/game_results_repository.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/presentation/game_over/timeline_report_screen.dart';
import 'package:mafia_nightfall/domain/engine/timeline_generator.dart';
import 'package:mafia_nightfall/data/services/interactive/interactive_service.dart';

class GameOverScreen extends ConsumerStatefulWidget {
  final String? interactiveSessionId;

  const GameOverScreen({super.key, this.interactiveSessionId});

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen> {
  bool _savingResult = false;
  bool _resultSaveFailed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioManagerProvider).playClick();
      ref.read(audioManagerProvider).playReveal();
      _saveGameToHistory();
    });
    final sessionId = widget.interactiveSessionId;
    if (sessionId != null &&
        ref.read(interactiveServiceProvider).protocolFor(sessionId) == 1) {
      unawaited(
        ref
            .read(interactiveServiceProvider)
            .endSession(sessionId)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _saveGameToHistory() async {
    if (_savingResult) return;
    setState(() {
      _savingResult = true;
      _resultSaveFailed = false;
    });
    final gameState = ref.read(gameOrchestratorProvider);
    final winner = gameState.winner;

    final String winnerStr;
    if (winner == Team.mafia) {
      winnerStr = 'المافيا';
    } else if (winner == Team.independent) {
      winnerStr = 'المهرج (الجوكر)';
    } else {
      winnerStr = 'المواطنون';
    }

    final narrative = TimelineGenerator.generateNarrative(gameState, winnerStr);

    final record = GameRecord(
      id: gameState.id,
      date: DateTime.now(),
      winningTeam: winnerStr,
      players: gameState.players
          .map(
            (p) => PlayerRecord(
              name: p.name,
              roleName: context.roleName(p.role),
              team: p.role.team == Team.mafia
                  ? 'المافيا'
                  : (p.role.team == Team.independent ? 'مستقل' : 'المواطنون'),
            ),
          )
          .toList(),
      newspaperText: narrative,
      gameStateJson: gameState.toJson(),
    );

    try {
      await ref
          .read(gameResultsRepositoryProvider)
          .save(
            record,
            gameState,
            serverOwned:
                widget.interactiveSessionId != null &&
                ref
                        .read(interactiveServiceProvider)
                        .protocolFor(widget.interactiveSessionId!) ==
                    2,
          );
    } catch (_) {
      if (mounted) setState(() => _resultSaveFailed = true);
    } finally {
      if (mounted) setState(() => _savingResult = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameOrchestratorProvider);
    final winner = gameState.winner;
    final isMafiaWin = winner == Team.mafia;
    final isJokerWin = winner == Team.independent;

    final winColor = isMafiaWin
        ? AppTheme.mafiaAccent
        : (isJokerWin ? Colors.purpleAccent : AppTheme.citizensAccent);
    final winTitle = isMafiaWin
        ? 'فازت المافيا!'
        : (isJokerWin ? 'فاز المهرج!' : 'فاز المواطنون!');
    final winSubtitle = isMafiaWin
        ? 'أحكمت المافيا قبضتها على المدينة'
        : (isJokerWin
              ? 'خدع المهرج الجميع وتم إقصاؤه!'
              : 'تم تطهير المدينة من الخونة');
    final winIcon = isMafiaWin
        ? Icons.local_fire_department
        : (isJokerWin ? Icons.sentiment_very_dissatisfied : Icons.shield);

    // Build final stats
    final allPlayers = gameState.players;
    final mafiaPlayers = allPlayers
        .where((p) => p.role.team == Team.mafia)
        .toList();
    final citiPlayers = allPlayers
        .where((p) => p.role.team != Team.mafia)
        .toList();
    final rounds = gameState.round;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_savingResult) const LinearProgressIndicator(),
              if (_resultSaveFailed)
                TextButton.icon(
                  onPressed: _saveGameToHistory,
                  icon: const Icon(Icons.cloud_off_outlined),
                  label: const Text('لم تُحفظ النتيجة · إعادة المحاولة'),
                ),
              const Spacer(),
              // Big win indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: winColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: winColor.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(winIcon, color: winColor, size: 72),
                    const SizedBox(height: 20),
                    Text(
                      winTitle,
                      style: TextStyle(
                        color: winColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      winSubtitle,
                      style: TextStyle(
                        color: context.visual.textSecondary,
                        fontFamily: 'Cairo',
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'عدد الجولات: $rounds',
                      style: TextStyle(
                        color: context.visual.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Player reveal
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppTheme.mafiaAccent,
                        unselectedLabelColor: context.visual.textSecondary,
                        indicatorColor: AppTheme.mafiaAccent,
                        labelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: [
                          Tab(text: 'المافيا: ${mafiaPlayers.length}'),
                          Tab(text: 'المواطنون: ${citiPlayers.length}'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _PlayerList(
                              players: mafiaPlayers,
                              teamColor: AppTheme.mafiaAccent,
                            ),
                            _PlayerList(
                              players: citiPlayers,
                              teamColor: AppTheme.citizensAccent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(gameOrchestratorProvider.notifier)
                            .endGame();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.visual.surface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.home),
                      label: const Text('الرئيسية'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TimelineReportScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.menu_book, color: Colors.black87),
                      label: const Text(
                        'جريدة المدينة',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  final List<Player> players;
  final Color teamColor;

  const _PlayerList({required this.players, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد',
          style: TextStyle(color: context.visual.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: players.length,
      itemBuilder: (ctx, i) {
        final p = players[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.visual.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: teamColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(AppTheme.roleImage(p.role)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      context.roleName(p.role),
                      style: TextStyle(
                        color: teamColor,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
