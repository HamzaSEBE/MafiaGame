import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mafia_nightfall/application/game_orchestrator.dart';
import 'package:mafia_nightfall/domain/enums/team.dart';
import 'package:mafia_nightfall/presentation/widgets/newspaper_widget.dart';
import 'dart:ui';

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
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'جريدة المدينة - اقرأ تفاصيل هذه المباراة الطاحنة!',
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameOrchestratorProvider);

    return Scaffold(
      
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [Color(0xFF2E2215), Color(0xFF100B07), Color(0xFF07070B)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'جريدة المدينة',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 15)],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.ios_share, color: Colors.white70),
                        onPressed: _shareReport,
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Screenshot(
                      controller: _screenshotController,
                      child: NewspaperWidget(gameState: gameState),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
