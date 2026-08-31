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
    // Sort by games played
    stats.sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  String _getBadge(PlayerStats stat) {
    if (stat.gamesPlayed < 2) return 'مبتدئ 👶';
    if (stat.killedFirstNight >= 2 && stat.killedFirstNight >= stat.gamesPlayed / 2) return 'المنحوس 💀';
    if (stat.mafiaWins >= 3 && stat.mafiaWins > stat.citizenWins) return 'العرّاب 👑';
    if (stat.citizenWins >= 3 && stat.citizenWins > stat.mafiaWins) return 'المحقق 🕵️';
    return 'لاعب خطير 🔥';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات اللاعبين'),
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
                    return Card(
                      color: AppTheme.surfaceHigh,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  stat.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.mafiaPrimary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getBadge(stat),
                                    style: const TextStyle(color: AppTheme.mafiaAccent, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(label: 'لعب', value: stat.gamesPlayed.toString(), color: Colors.blueAccent),
                                _StatItem(label: 'فوز مافيا', value: stat.mafiaWins.toString(), color: AppTheme.mafiaPrimary),
                                _StatItem(label: 'فوز مواطن', value: stat.citizenWins.toString(), color: AppTheme.citizensPrimary),
                              ],
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
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'Cairo')),
      ],
    );
  }
}