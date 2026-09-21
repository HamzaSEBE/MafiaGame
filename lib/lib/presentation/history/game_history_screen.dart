import 'package:mafia_nightfall/presentation/widgets/newspaper_widget.dart';
import 'dart:ui';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('مسح السجل', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد أنك تريد مسح جميع السجلات؟', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('مسح', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.clearHistory();
      _loadHistory();
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} - ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _showNewspaperDialog(BuildContext context, String? text) {
    if (text == null || text.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NewspaperWidget(narrative: text),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق الجريدة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('سجل المباريات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          _history == null
              ? const Center(child: CircularProgressIndicator(color: AppTheme.mafiaPrimary))
              : _history!.isEmpty
                  ? const Center(child: Text('لا يوجد سجل بعد', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 18)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history!.length,
                      itemBuilder: (context, index) {
                        final record = _history![index];
                        final isMafiaWin = record.winningTeam == 'المافيا' || record.winningTeam == 'mafia';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isMafiaWin 
                                  ? [const Color(0xFF3A1515), const Color(0xFF1A0A0A)]
                                  : [const Color(0xFF15223A), const Color(0xFF0A101A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isMafiaWin ? Colors.redAccent.withValues(alpha: 0.3) : Colors.blueAccent.withValues(alpha: 0.3),
                              width: 1.5
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isMafiaWin ? Colors.redAccent.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.1),
                                blurRadius: 15,
                                spreadRadius: -5,
                              )
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showNewspaperDialog(context, record.newspaperText),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDate(record.date),
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontFamily: 'Arial'),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isMafiaWin ? Colors.redAccent.withValues(alpha: 0.15) : Colors.blueAccent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: isMafiaWin ? Colors.redAccent.withValues(alpha: 0.5) : Colors.blueAccent.withValues(alpha: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(isMafiaWin ? Icons.local_fire_department : Icons.shield, size: 16, color: isMafiaWin ? Colors.redAccent : Colors.blueAccent),
                                            const SizedBox(width: 6),
                                            Text(
                                              'انتصار ${isMafiaWin ? 'المافيا' : 'المواطنين'}',
                                              style: TextStyle(
                                                color: isMafiaWin ? Colors.redAccent : Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Players List (Luxurious wrap)
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: record.players.map((p) {
                                      final isPmafia = p.team == 'mafia' || p.team == 'المافيا';
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          border: Border.all(color: isPmafia ? Colors.red.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3)),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${p.name} • ',
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              p.roleName,
                                              style: TextStyle(color: isPmafia ? Colors.redAccent : Colors.blueAccent, fontSize: 12, fontFamily: 'Cairo'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  const Divider(color: Colors.white10, thickness: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.touch_app, size: 16, color: Colors.orangeAccent),
                                      const SizedBox(width: 8),
                                      Text(
                                        'اضغط لقراءة تقرير المعركة',
                                        style: TextStyle(color: Colors.orangeAccent.withValues(alpha: 0.8), fontSize: 13, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
