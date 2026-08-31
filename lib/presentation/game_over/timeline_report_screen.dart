import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/domain/engine/timeline_generator.dart';
import 'package:mafia_nightfall/presentation/theme/app_theme.dart';

class TimelineReportScreen extends ConsumerStatefulWidget {
  const TimelineReportScreen({super.key});

  @override
  ConsumerState<TimelineReportScreen> createState() => _TimelineReportScreenState();
}

class _TimelineReportScreenState extends ConsumerState<TimelineReportScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  void _shareReport() async {
    setState(() => _isCapturing = true);
    
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final dir = await getApplicationDocumentsDirectory();
        final file = await File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(image);
        
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'جريدة المدينة - نتائج لعبة مافيا عالشوارب 🔥',
        );
      }
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameOrchestratorProvider);
    final winnerStr = gameState.winner == Team.mafia ? 'المافيا' : 'المواطنون';
    final narrative = TimelineGenerator.generateNarrative(gameState.eventHistory, winnerStr);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جريدة المدينة'),
        actions: [
          if (!_isCapturing)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.amber),
              onPressed: _shareReport,
              tooltip: 'مشاركة',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Screenshot(
          controller: _screenshotController,
          child: Container(
            color: AppTheme.background, // Ensure background is captured
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.menu_book_rounded, size: 64, color: AppTheme.citizensAccent),
                const SizedBox(height: 16),
                Text(
                  narrative,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontFamily: 'Cairo',
                    height: 1.6,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 24),
                const Divider(color: AppTheme.surfaceHigh),
                const SizedBox(height: 8),
                const Text(
                  'تم الإنشاء بواسطة: تطبيق مافيا عالشوارب 🕵️‍♂️',
                  style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}