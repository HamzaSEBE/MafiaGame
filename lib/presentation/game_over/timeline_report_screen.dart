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
import 'dart:ui';

class TimelineReportScreen extends ConsumerStatefulWidget {
  const TimelineReportScreen({super.key});

  @override
  ConsumerState<TimelineReportScreen> createState() => _TimelineReportScreenState();
}

class _TimelineReportScreenState extends ConsumerState<TimelineReportScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

    Widget _buildRichText(String text) {
    List<TextSpan> spans = [];
    final lines = text.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      
      if (line.startsWith('[ أحداث الليلة') || line.startsWith('[ نهار اليوم')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            color: Colors.amber, 
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            height: 2,
          ),
        ));
      } else if (line.startsWith('النتيجة النهائية:')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            color: Colors.redAccent, 
            fontSize: 20, 
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            height: 2,
          ),
        ));
      } else {
        final RegExp exp = RegExp(r'\(\$(.*?)\)');
        int start = 0;
        final matches = exp.allMatches(line);
        
        for (final match in matches) {
          if (match.start > start) {
            spans.add(TextSpan(text: line.substring(start, match.start)));
          }
          spans.add(TextSpan(
            text: match.group(1),
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ));
          start = match.end;
        }
        
        if (start < line.length) {
          spans.add(TextSpan(text: line.substring(start)));
        }
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return RichText(
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontFamily: 'Cairo',
          height: 1.8,
        ),
        children: spans,
      ),
    );
  }


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
    final winnerStr = gameState.winner == Team.mafia ? 'المافيا' : 'المواطنون';
    final narrative = TimelineGenerator.generateNarrative(gameState, winnerStr);

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      body: Stack(
        children: [
          // Elegant Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [Color(0xFF2E2215), Color(0xFF100B07), Color(0xFF07070B)], // Vintage dark newspaper feel
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
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
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Screenshot(
                      controller: _screenshotController,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16120E).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orangeAccent.withValues(alpha: 0.05),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Newspaper Logo/Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.local_library, size: 40, color: Colors.orangeAccent),
                                    const SizedBox(width: 12),
                                    Column(
                                      children: [
                                        const Text(
                                          'أخبار المافيا العاجلة',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        Text(
                                          'العدد الخاص - الحقيقة تكشف',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 12,
                                            fontFamily: 'Cairo',
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Divider(color: Colors.white24, thickness: 1),
                                const SizedBox(height: 24),
                                
                                // Dynamic Narrative
                                _buildRichText(narrative),
                                
                                const SizedBox(height: 40),
                                const Divider(color: Colors.white24, thickness: 1),
                                const SizedBox(height: 12),
                                Text(
                                  'تم توثيق هذه الأحداث رسمياً في أرشيف المدينة',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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