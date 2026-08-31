import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/domain/enums/phase.dart';
import 'package:mafia_nightfall/domain/events/game_event.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/home/home_screen.dart';

import 'package:mafia_nightfall/data/repositories/history_repository.dart';
import 'package:mafia_nightfall/data/repositories/player_stats_repository.dart';
import 'package:mafia_nightfall/core/audio/audio_manager.dart';
import 'package:mafia_nightfall/presentation/game_over/timeline_report_screen.dart';

class GameOverScreen extends ConsumerStatefulWidget {
  const GameOverScreen({super.key});

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioManagerProvider).stopMusic();
      ref.read(audioManagerProvider).playSuccess();
    });
    _saveGameToHistory();
  }

  Future<void> _saveGameToHistory() async {
    final gameState = ref.read(gameOrchestratorProvider);
    final winner = gameState.winner;
    final isMafiaWin = winner == Team.mafia;
    
    final record = GameRecord(
      id: gameState.id,
      date: DateTime.now(),
      winningTeam: isMafiaWin ? 'مافيا' : 'مواطنون',
      players: gameState.players.map((p) => PlayerRecord(
        name: p.name,
        roleName: AppTheme.roleArabicName(p.role),
        team: p.role.team == Team.mafia ? 'مافيا' : 'مواطنون',
      )).toList(),
    );
    
    final repo = HistoryRepository();
    await repo.addGame(record);

    // Update Player Stats
    final statsRepo = ref.read(playerStatsRepoProvider);
    final firstNightVictims = gameState.eventHistory
        .where((e) => e.round == 1 && e.phase == Phase.nightResolution && e.type == EventType.nightResolutionSummary)
        .expand((e) => (e.metadata['assassinatedIds'] as List?)?.cast<String>() ?? <String>[])
        .toList();

    for (final player in gameState.players) {
      final isMafia = player.role.team == Team.mafia;
      await statsRepo.updateStatsForPlayer(
        player.name,
        played: true,
        wonAsMafia: isMafiaWin && isMafia,
        wonAsCitizen: !isMafiaWin && !isMafia,
        diedFirstNight: firstNightVictims.contains(player.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameOrchestratorProvider);
    final winner = gameState.winner;
    final isMafiaWin = winner == Team.mafia;

    final winColor    = isMafiaWin ? AppTheme.mafiaAccent  : AppTheme.citizensAccent;
    final winTitle    = isMafiaWin ? 'فازت المافيا!'       : 'فاز المواطنون!';
    final winSubtitle = isMafiaWin ? 'أحكمت المافيا قبضتها على المدينة' : 'تم تطهير المدينة من الخونة';
    final winIcon     = isMafiaWin ? Icons.local_fire_department : Icons.shield;

    // Build final stats
    final allPlayers   = gameState.players;
    final mafiaPlayers = allPlayers.where((p) => p.role.team == Team.mafia).toList();
    final citiPlayers  = allPlayers.where((p) => p.role.team != Team.mafia).toList();
    final rounds       = gameState.round;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Big win indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  color: winColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: winColor.withValues(alpha: 0.4), width: 2),
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
                      style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'عدد الجولات: $rounds',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
                        unselectedLabelColor: AppTheme.textSecondary,
                        indicatorColor: AppTheme.mafiaAccent,
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                        tabs: [
                          Tab(text: 'المافيا (${mafiaPlayers.length})'),
                          Tab(text: 'المواطنون (${citiPlayers.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _PlayerList(players: mafiaPlayers, teamColor: AppTheme.mafiaAccent),
                            _PlayerList(players: citiPlayers, teamColor: AppTheme.citizensAccent),
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
                      onPressed: () {
                        ref.read(gameOrchestratorProvider.notifier).resetGame();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface,
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
                          MaterialPageRoute(builder: (_) => const TimelineReportScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.menu_book, color: Colors.black87),
                      label: const Text('جريدة المدينة', style: TextStyle(color: Colors.black87)),
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
      return const Center(child: Text('لا يوجد', style: TextStyle(color: AppTheme.textSecondary)));
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
            color: AppTheme.surfaceHigh,
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
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo', color: Colors.white)),
                    Text(AppTheme.roleArabicName(p.role), style: TextStyle(color: teamColor, fontSize: 13, fontFamily: 'Cairo')),
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