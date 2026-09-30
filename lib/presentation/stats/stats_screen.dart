import 'package:flutter/material.dart';
import 'package:mafia_nightfall/presentation/premium/themes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/domain/entities/player_stats.dart';
import 'package:mafia_nightfall/data/repositories/player_stats_repository.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  void _shareStats() async {
    setState(() => _isCapturing = true);
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final dir = await getApplicationDocumentsDirectory();
        final file = await File('${dir.path}/stats_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(image);
        await Share.shareXFiles([XFile(file.path)], text: 'إحصائيات لعبة مافيا - Mafia Nightfall 🔥');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedThemeProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Background Gradient (Performance friendly, no blurs)
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
            child: Screenshot(
              controller: _screenshotController,
              child: Container(
                color: const Color(0xFF0A0A0F), // For screenshot background
                child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<List<PlayerStats>>(
                    future: ref.read(playerStatsRepoProvider).loadStats(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: AppTheme.mafiaPrimary));
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('خطأ في تحميل البيانات', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')));
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
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'إحصائيات اللاعبين',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo',
                shadows: [Shadow(color: AppTheme.mafiaAccent, blurRadius: 20)],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'حذف جميع الإحصائيات',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('حذف جميع الإحصائيات؟', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  content: Text('سيتم حذف إحصائيات جميع اللاعبين نهائياً. هل أنت متأكد؟', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(playerStatsRepoProvider).clearStats();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حذف جميع الإحصائيات', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.redAccent),
                          );
                          // Force rebuild
                          (context as Element).markNeedsBuild();
                        }
                      },
                      child: Text('حذف الكل', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              );
            },
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16120E).withValues(alpha: 0.9), // Solid dark color instead of Blur
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTop ? rankColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05), width: 1.5),
        // Simple subtle shadow (better performance)
        boxShadow: isTop ? [BoxShadow(color: rankColor.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 0)] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [rankColor.withValues(alpha: 0.2), rankColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: rankColor.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 18,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.sports_esports, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        '${p.gamesPlayed} مباراة',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6), fontFamily: 'Cairo'),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.emoji_events, size: 14, color: AppTheme.citizensPrimary.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(
                        '${p.mafiaWins + p.citizenWins} فوز',
                        style: TextStyle(fontSize: 12, color: AppTheme.citizensPrimary.withValues(alpha: 0.8), fontFamily: 'Cairo', fontWeight: FontWeight.bold),
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
                  style: TextStyle(
                    fontSize: 20,
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
    );
  }
}