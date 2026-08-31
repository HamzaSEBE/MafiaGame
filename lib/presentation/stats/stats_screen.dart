import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/data/repositories/player_stats_repository.dart';
import 'package:mafia_nightfall/domain/entities/player_stats.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  List<PlayerStats> _stats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = ref.read(playerStatsRepoProvider);
    final stats = await repo.loadStats();
    
    // Sort logic: Best to worst
    // 1. Total Wins
    // 2. Win Rate
    // 3. Games Played
    stats.sort((a, b) {
      final winsA = a.mafiaWins + a.citizenWins;
      final winsB = b.mafiaWins + b.citizenWins;
      
      if (winsA != winsB) {
        return winsB.compareTo(winsA);
      }
      
      final rateA = a.gamesPlayed == 0 ? 0 : winsA / a.gamesPlayed;
      final rateB = b.gamesPlayed == 0 ? 0 : winsB / b.gamesPlayed;
      if (rateA != rateB) {
        return rateB.compareTo(rateA);
      }
      
      return b.gamesPlayed.compareTo(a.gamesPlayed);
    });

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  String _getBadge(PlayerStats stat) {
    if (stat.gamesPlayed < 3) return 'مبتدئ 👶';
    if (stat.killedFirstNight > 0 && stat.killedFirstNight >= stat.gamesPlayed * 0.3) return 'المنحوس 💀';
    
    final totalWins = stat.mafiaWins + stat.citizenWins;
    final winRate = stat.gamesPlayed == 0 ? 0 : totalWins / stat.gamesPlayed;
    
    if (stat.mafiaWins >= 2 && stat.mafiaWins > stat.citizenWins) return 'العرّاب 👑';
    if (stat.citizenWins >= 2 && stat.citizenWins > stat.mafiaWins) return 'المحقق 🕵️';
    if (winRate >= 0.6) return 'محترف 🌟';
    
    return 'لاعب عادي 👤';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات اللاعبين الأساطير'),
        backgroundColor: AppTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
              ? const Center(child: Text('لا توجد إحصائيات بعد. العب جولة لتسجيل البيانات!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stats.length,
                  itemBuilder: (context, index) {
                    final stat = _stats[index];
                    final losses = stat.gamesPlayed - (stat.mafiaWins + stat.citizenWins);
                    final rankColor = index == 0 ? Colors.amber : (index == 1 ? Colors.grey[400] : (index == 2 ? Colors.brown[300] : AppTheme.surfaceHigh));
                    final isTop3 = index < 3;
                    
                    return Card(
                      color: AppTheme.surfaceHigh,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isTop3 ? BorderSide(color: rankColor!, width: 2) : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (isTop3) ...[
                                      Icon(Icons.emoji_events, color: rankColor, size: 28),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      '${index + 1}. ${stat.name}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.mafiaAccent.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    _getBadge(stat),
                                    style: const TextStyle(color: AppTheme.mafiaAccent, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.background.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _StatItem(label: 'لعب', value: stat.gamesPlayed.toString(), color: Colors.blueAccent),
                                  _StatItem(label: 'فاز مافيا', value: stat.mafiaWins.toString(), color: AppTheme.mafiaPrimary),
                                  _StatItem(label: 'فاز مواطن', value: stat.citizenWins.toString(), color: AppTheme.citizensPrimary),
                                  _StatItem(label: 'خسارة', value: losses.toString(), color: AppTheme.error),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
      ],
    );
  }
}