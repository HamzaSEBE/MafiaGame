import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/domain/entities/player_stats.dart';
import 'package:mafia_nightfall/data/repositories/player_stats_repository.dart';
import 'dart:ui';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.8),
                  radius: 1.5,
                  colors: [Color(0xFF2A1115), Color(0xFF0F0811), Color(0xFF07070B)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<List<PlayerStats>>(
                    future: ref.read(playerStatsRepoProvider).loadStats(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.mafiaPrimary));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('خطأ في تحميل البيانات', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')));
                      }
                      final players = snapshot.data ?? [];
                      if (players.isEmpty) {
                        return const Center(child: Text('لا توجد إحصائيات بعد', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 18)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final p = players[index];
                          return _buildStatCard(p, index + 1);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'إحصائيات اللاعبين',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
              shadows: [Shadow(color: AppTheme.mafiaAccent, blurRadius: 20)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(PlayerStats p, int rank) {
    final winRate = p.gamesPlayed > 0 ? ((p.mafiaWins + p.citizenWins) / p.gamesPlayed * 100).toStringAsFixed(1) : '0.0';
    
    // Premium glow for top 3
    final bool isTop = rank <= 3;
    final Color rankColor = rank == 1 ? const Color(0xFFFFD700) : rank == 2 ? const Color(0xFFC0C0C0) : rank == 3 ? const Color(0xFFCD7F32) : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isTop ? rankColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05), width: 1.5),
        boxShadow: isTop ? [BoxShadow(color: rankColor.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: -5)] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTop ? rankColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isTop ? rankColor : Colors.white54,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Player Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.sports_esports, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            '${p.gamesPlayed} مباراة',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6), fontFamily: 'Cairo'),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.emoji_events, size: 14, color: AppTheme.citizensPrimary.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            '${(p.mafiaWins + p.citizenWins)} فوز',
                            style: TextStyle(fontSize: 13, color: AppTheme.citizensPrimary.withValues(alpha: 0.8), fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Win Rate
                Column(
                  children: [
                    Text(
                      '$winRate%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Arial',
                      ),
                    ),
                    Text(
                      'نسبة الفوز',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}