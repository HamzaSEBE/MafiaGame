import 'dart:io';

void main() {
  final file = File('lib/presentation/reveal/role_reveal_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("AudioManager.playClick()", "ref.read(audioManagerProvider).playClick()");
  content = content.replaceAll("AudioManager.playGunshot()", "ref.read(audioManagerProvider).playKill()");
  content = content.replaceAll("AudioManager.playReveal()", "ref.read(audioManagerProvider).playReveal()");
  
  // Replace _currentPlayer.role.team with a manual check or AppTheme
  content = content.replaceAll("_currentPlayer.role.team == Team.mafia", "(_currentPlayer.role.name.toLowerCase().contains('mafia'))");
  
  file.writeAsStringSync(content);
}