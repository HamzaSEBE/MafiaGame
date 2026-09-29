import 'dart:io';

void main() {
  final file = File('lib/presentation/stats/stats_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll('playerStatsRepositoryProvider', 'playerStatsRepoProvider');
  content = content.replaceAll('final statsStream = ref.watch(playerStatsRepoProvider).watchTopPlayers();', '');
  
  content = content.replaceAll('p.playerName', 'p.name');
  content = content.replaceAll('p.gamesWon', '(p.mafiaWins + p.citizenWins)');
  
  // Replace the StreamBuilder with a FutureBuilder calling loadStats()
  final oldBuilder = """
                Expanded(
                  child: StreamBuilder<List<PlayerStats>>(
                    stream: statsStream,
""";
  final newBuilder = """
                Expanded(
                  child: FutureBuilder<List<PlayerStats>>(
                    future: ref.read(playerStatsRepoProvider).loadStats(),
""";
  content = content.replaceFirst(oldBuilder, newBuilder);

  file.writeAsStringSync(content);
  print('Fixed stats screen!');
}