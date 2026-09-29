import 'dart:io';

void main() {
  final file = File('lib/presentation/stats/stats_screen.dart');
  String content = file.readAsStringSync();

  // Add imports if missing
  if (!content.contains('package:screenshot/screenshot.dart')) {
    content = content.replaceFirst(
      "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:screenshot/screenshot.dart';\nimport 'package:share_plus/share_plus.dart';\nimport 'package:path_provider/path_provider.dart';\nimport 'dart:io';"
    );
  }

  // Convert to Stateful
  if (content.contains('class StatsScreen extends ConsumerWidget {')) {
    content = content.replaceFirst(
      'class StatsScreen extends ConsumerWidget {\n  const StatsScreen({super.key});\n\n  @override\n  Widget build(BuildContext context, WidgetRef ref) {',
      '''class StatsScreen extends ConsumerStatefulWidget {
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
        final file = await File('\${dir.path}/stats_\${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(image);
        await Share.shareXFiles([XFile(file.path)], text: 'إحصائيات لعبة مافيا - Mafia Nightfall 🔥');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {'''
    );
  }

  // Replace _buildHeader signature and add button
  if (content.contains('Widget _buildHeader(BuildContext context, WidgetRef ref) {')) {
    content = content.replaceFirst(
      'Widget _buildHeader(BuildContext context, WidgetRef ref) {',
      'Widget _buildHeader(BuildContext context) {'
    );
    // Remove ref argument from call
    content = content.replaceFirst('_buildHeader(context, ref)', '_buildHeader(context)');

    // Add share button
    content = content.replaceFirst(
      '''
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
''',
      '''
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
'''
    );
    
    // We can just add the share button next to the title
    content = content.replaceFirst(
      '''
          const Text(
            'الإحصائيات المظلمة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              shadows: [Shadow(color: AppTheme.mafiaPrimary, blurRadius: 10)],
            ),
          ),
          const SizedBox(width: 48), // balance
''',
      '''
          const Text(
            'الإحصائيات المظلمة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              shadows: [Shadow(color: AppTheme.mafiaPrimary, blurRadius: 10)],
            ),
          ),
          _isCapturing 
            ? const SizedBox(width: 48)
            : IconButton(
                icon: const Icon(Icons.ios_share, color: Colors.white70),
                onPressed: _shareStats,
              ),
'''
    );
  }

  // Wrap the main content with Screenshot
  content = content.replaceFirst(
    '''
          SafeArea(
            child: Column(
''',
    '''
          SafeArea(
            child: Screenshot(
              controller: _screenshotController,
              child: Container(
                color: const Color(0xFF0A0A0F), // For screenshot background
                child: Column(
'''
  );

  // Close the Container and Screenshot
  content = content.replaceFirst(
    '''
              ],
            ),
          ),
        ],
''',
    '''
                ],
              ),
            ),
          ),
        ],
'''
  );

  file.writeAsStringSync(content);
}
