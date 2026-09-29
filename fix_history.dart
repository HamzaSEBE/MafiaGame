import 'dart:io';

void main() {
  final file = File('lib/presentation/history/game_history_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll('record.winnerTeam', 'record.winningTeam');
  content = content.replaceAll('record.timelineNarrative', 'record.newspaperText');
  content = content.replaceAll('record.timestamp', 'record.date');
  content = content.replaceAll('record.playersCount', 'record.players.length');
  content = content.replaceAll("\${record.totalRounds}", "N/A");
  
  file.writeAsStringSync(content);
  print('Fixed history screen!');
}