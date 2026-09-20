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
    if (text == null || text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الجريدة غير متوفرة لهذه المباراة', style: TextStyle(fontFamily: 'Cairo'))));
       return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF16120E).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.05), blurRadius: 30, spreadRadius: 5)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_library, size: 36, color: Colors.orangeAccent),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            const Text(
                              'أخبار المافيا العاجلة',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                            ),
                            Text(
                              'أرشيف الجرائم',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontFamily: 'Cairo', letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 24),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        height: 1.8,
                        wordSpacing: 1,
                      ),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إغلاق الأرشيف', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              ),
            ),
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
                        
                        return Card(
                          color: const Color(0xFF1E1E24).withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isMafiaWin ? Colors.red.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3)),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showNewspaperDialog(context, record.newspaperText),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(record.date),
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isMafiaWin ? Colors.red.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'الفائز: ${isMafiaWin ? 'المافيا' : 'المواطنون'}',
                                          style: TextStyle(
                                            color: isMafiaWin ? Colors.redAccent : Colors.blueAccent,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatColumn('اللاعبين', '${record.players.length}', Icons.people),
                                      _buildStatColumn('الجولات', 'N/A', Icons.autorenew),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.white10),
                                  const Center(
                                    child: Text(
                                      'اضغط لقراءة الجريدة',
                                      style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontFamily: 'Cairo'),
                                    ),
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

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'Cairo')),
      ],
    );
  }
}