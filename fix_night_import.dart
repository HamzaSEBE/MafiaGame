import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('audio_manager.dart')) {
    content = "import 'package:mafia_nightfall/core/audio/audio_manager.dart';\n" + content;
    file.writeAsStringSync(content);
  }
}