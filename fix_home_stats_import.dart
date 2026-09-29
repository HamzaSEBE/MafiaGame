import 'dart:io';

void main() {
  final file = File('lib/presentation/home/home_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "import 'package:mafia_nightfall/presentation/stats/player_stats_screen.dart';",
    "import 'package:mafia_nightfall/presentation/stats/stats_screen.dart';"
  );
  content = content.replaceAll(
    "const PlayerStatsScreen()",
    "const StatsScreen()"
  );

  file.writeAsStringSync(content);
  print('Fixed home screen imports!');
}