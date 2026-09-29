import 'dart:io';

void main() {
  final file = File('lib/presentation/home/home_screen.dart');
  String content = file.readAsStringSync();

  // Add Instructions import
  if (!content.contains('instructions_screen.dart')) {
    content = content.replaceFirst(
      "import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';",
      "import 'package:mafia_nightfall/presentation/setup/setup_screen.dart';\nimport 'package:mafia_nightfall/presentation/instructions/instructions_screen.dart';"
    );
  }

  // Find the Start Action Buttons
  final startStr = '''
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
''';
  final endStr = '''
                    ],
                  ),
                ),
''';

  final startIndex = content.indexOf(startStr);
  final endIndex = content.indexOf(endStr, startIndex);

  if (startIndex != -1 && endIndex != -1) {
    final newButtons = '''                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.qr_code_scanner,
                        label: 'لعب تفاعلي (QR)',
                        primary: true,
                        colorOverride: const Color(0xFFFF512F),
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen(isInteractive: true)));
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.phone_android,
                        label: 'لعب محلي (جهاز واحد)',
                        primary: false,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen(isInteractive: false)));
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.public,
                        label: 'لعب عبر الإنترنت (قريباً 🔥)',
                        primary: false,
                        colorOverride: Colors.grey.shade800,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً جداً! حماس 🔥', style: TextStyle(fontFamily: 'Cairo'))));
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLuxuriousButton(
                              context: context,
                              ref: ref,
                              icon: Icons.leaderboard,
                              label: 'الإحصائيات',
                              primary: false,
                              onTap: () {
                                ref.read(audioManagerProvider).playClick();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLuxuriousButton(
                              context: context,
                              ref: ref,
                              icon: Icons.history_edu,
                              label: 'السجل',
                              primary: false,
                              onTap: () {
                                ref.read(audioManagerProvider).playClick();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GameHistoryScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.help_outline,
                        label: 'كيف تلعب؟ (تعليمات)',
                        primary: false,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructionsScreen()));
                        },
                      ),
''';
    content = content.replaceRange(startIndex, endIndex, newButtons);
  }

  // Update _buildLuxuriousButton signature
  if (!content.contains('Color? colorOverride')) {
    content = content.replaceAll(
      'required bool primary,\n    required VoidCallback onTap,',
      'required bool primary,\n    required VoidCallback onTap,\n    Color? colorOverride,'
    );
    
    // Replace gradient color if colorOverride exists
    content = content.replaceFirst(
      'colors: [Color(0xFF8B0000), Color(0xFF4A0000)], // Mafia Red to Dark Red',
      'colors: colorOverride != null ? [colorOverride, colorOverride.withOpacity(0.6)] : [const Color(0xFF8B0000), const Color(0xFF4A0000)],'
    );
  }
  
  file.writeAsStringSync(content);
}
