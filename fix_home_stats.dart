import 'dart:io';

void main() {
  final file = File('lib/presentation/home/home_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('PlayerStatsScreen')) {
    content = "import 'package:mafia_nightfall/presentation/stats/player_stats_screen.dart';\n" + content;
  }

  final buttonCode = """
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.history_edu,
                        label: 'سجل المباريات',
""";

  final newButtonsCode = """
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.leaderboard,
                        label: 'إحصائيات اللاعبين',
                        primary: false,
                        onTap: () {
                          ref.read(audioManagerProvider).playClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlayerStatsScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLuxuriousButton(
                        context: context,
                        ref: ref,
                        icon: Icons.history_edu,
                        label: 'سجل المباريات',
""";

  content = content.replaceFirst(buttonCode, newButtonsCode);
  
  file.writeAsStringSync(content);
  print('Added PlayerStats to Home Screen!');
}