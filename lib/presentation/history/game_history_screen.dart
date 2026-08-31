import 'package:flutter/material.dart';
import 'package:mafia_nightfall/data/repositories/history_repository.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';
import 'package:mafia_nightfall/presentation/widgets/animated_background.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  final HistoryRepository _repo = HistoryRepository();
  List<GameRecord>? _history;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _repo.getHistory();
    setState(() => _history = history);
  }
  
  Future<void> _clearHistory() async {
    await _repo.clearHistory();
    _loadHistory();
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} - ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('سجل الألعاب السابقة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            tooltip: 'مسح السجل',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surface,
                  title: const Text('مسح السجل بالكامل؟', style: TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                  content: const Text('سيتم حذف جميع الألعاب السابقة ولن تتمكن من استعادتها.', style: TextStyle(fontFamily: 'Cairo')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearHistory();
                      },
                      child: const Text('نعم، مسح'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: _history == null 
              ? const Center(child: CircularProgressIndicator())
              : _history!.isEmpty 
                ? const Center(child: Text('لا يوجد سجل للألعاب حتى الآن', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 18)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history!.length,
                    itemBuilder: (context, index) {
                      final game = _history![index];
                      final isMafiaWin = game.winningTeam == 'مافيا';
                      final color = isMafiaWin ? AppTheme.mafiaAccent : AppTheme.citizensAccent;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: AppTheme.surface.withValues(alpha: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5)
                        ),
                        child: ExpansionTile(
                          collapsedIconColor: color,
                          iconColor: color,
                          title: Row(
                            children: [
                              Icon(isMafiaWin ? Icons.local_fire_department : Icons.shield, color: color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('فاز ${game.winningTeam}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
                                    Text(_formatDate(game.date), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.background.withValues(alpha: 0.5),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('اللاعبون في هذه اللعبة:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: game.players.map((p) {
                                      final pColor = p.team == 'مافيا' ? AppTheme.mafiaPrimary : AppTheme.citizensPrimary;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: pColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: pColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text('${p.name} (${p.roleName})', style: TextStyle(color: pColor, fontSize: 12, fontFamily: 'Cairo')),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
