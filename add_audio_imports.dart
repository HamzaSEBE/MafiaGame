import 'dart:io';

void main() {
  // Add vote SFX to voting screen
  final votingFile = File('lib/presentation/voting/voting_screen.dart');
  var content = votingFile.readAsStringSync();
  
  if (!content.contains('audio_manager.dart')) {
    content = "import 'package:mafia_nightfall/core/audio/audio_manager.dart';\n" + content;
    votingFile.writeAsStringSync(content);
    print('Added audio import to voting_screen.dart');
  }
  
  // Add reveal SFX to role reveal screen
  final revealFile = File('lib/presentation/reveal/role_reveal_screen.dart');
  content = revealFile.readAsStringSync();
  
  if (!content.contains('audio_manager.dart')) {
    content = "import 'package:mafia_nightfall/core/audio/audio_manager.dart';\n" + content;
    revealFile.writeAsStringSync(content);
    print('Added audio import to role_reveal_screen.dart');
  }
  
  print('Done adding audio imports!');
}