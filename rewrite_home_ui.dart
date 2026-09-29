import 'dart:io';

void main() {
  final file = File('lib/presentation/home/home_screen.dart');
  String content = file.readAsStringSync();

  final startStr = '                // Action Buttons';
  final endStr = '                const SizedBox(height: 48),';

  final startIndex = content.indexOf(startStr);
  final endIndex = content.indexOf(endStr);

  if (startIndex != -1 && endIndex != -1) {
    final newButtons = '''                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Primary Interactive Mode Button
                      _buildGameModeCard(
                        context: context,
                        ref: ref,
                        title: 'لعب تفاعلي',
                        subtitle: 'يمسح كل لاعب الكود من هاتفه',
                        icon: Icons.qr_code_scanner,
                        isPrimary: true,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen(isInteractive: true)));
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Secondary Offline Mode Button
                      _buildGameModeCard(
                        context: context,
                        ref: ref,
                        title: 'لعب محلي',
                        subtitle: 'تمرير جهاز واحد بين جميع اللاعبين',
                        icon: Icons.phone_android,
                        isPrimary: false,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen(isInteractive: false)));
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Hype Online Button
                      _buildOnlineTeaser(context, ref),
                      
                      const SizedBox(height: 24),
                      
                      // Secondary Actions Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallActionButton(
                              context: context,
                              ref: ref,
                              icon: Icons.leaderboard,
                              label: 'الإحصائيات',
                              onTap: () {
                                ref.read(audioManagerProvider).playClick();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSmallActionButton(
                              context: context,
                              ref: ref,
                              icon: Icons.history_edu,
                              label: 'السجل',
                              onTap: () {
                                ref.read(audioManagerProvider).playClick();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GameHistoryScreen()));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSmallActionButton(
                              context: context,
                              ref: ref,
                              icon: Icons.menu_book,
                              label: 'التعليمات',
                              onTap: () {
                                ref.read(audioManagerProvider).playClick();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructionsScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
''';
    content = content.replaceRange(startIndex, endIndex, newButtons);
  }
  
  // Replace _buildLuxuriousButton with the new widget builders
  final luxuriousStart = content.indexOf('Widget _buildLuxuriousButton');
  final luxuriousEnd = content.lastIndexOf('}') + 1; // Actually this might be risky, I'll use regex or replace it directly
  
  if (luxuriousStart != -1) {
    final before = content.substring(0, luxuriousStart);
    // Find the end of _buildLuxuriousButton
    int bracesCount = 0;
    int endIdx = luxuriousStart;
    bool foundFirstBrace = false;
    for (int i = luxuriousStart; i < content.length; i++) {
      if (content[i] == '{') {
        bracesCount++;
        foundFirstBrace = true;
      } else if (content[i] == '}') {
        bracesCount--;
      }
      if (foundFirstBrace && bracesCount == 0) {
        endIdx = i + 1;
        break;
      }
    }
    
    final after = content.substring(endIdx);
    
    final newWidgets = '''
  Widget _buildGameModeCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF4A0000)], // Deep Mafia Red
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isPrimary ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
            width: isPrimary ? 1.5 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineTeaser(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(audioManagerProvider).playClick();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نعمل على إضافة هذه الميزة قريباً! 🔥', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Color(0xFF8B0000),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF15101A), // Dark purple/black tint
          border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.public, color: Colors.deepPurpleAccent.withValues(alpha: 0.3), size: 36),
                const Icon(Icons.public, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'أونلاين',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'قريباً 🔥',
                          style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'العب مع أصدقائك عن بُعد',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
''';
    
    content = before + newWidgets + after;
  }
  
  file.writeAsStringSync(content);
}
