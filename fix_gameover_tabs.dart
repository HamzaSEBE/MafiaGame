import 'dart:io';

void main() {
  final file = File('lib/presentation/game_over/game_over_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("Tab(text: 'المافيا (\${mafiaPlayers.length})'),", "Tab(text: 'المافيا: \${mafiaPlayers.length}'),");
  content = content.replaceAll("Tab(text: 'المواطنون (\${citiPlayers.length})'),", "Tab(text: 'المواطنون: \${citiPlayers.length}'),");
  // Some PowerShell garbled Arabic might be there:
  content = content.replaceAll("Tab(text: 'O U,U.O U?USO  (\${mafiaPlayers.length})'),", "Tab(text: 'المافيا: \${mafiaPlayers.length}'),");
  content = content.replaceAll("Tab(text: 'O U,U.U^O OU+U^U+ (\${citiPlayers.length})'),", "Tab(text: 'المواطنون: \${citiPlayers.length}'),");
  
  file.writeAsStringSync(content);
  print('Fixed game over tabs!');
}