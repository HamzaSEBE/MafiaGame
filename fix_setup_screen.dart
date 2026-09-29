import 'dart:io';

void main() {
  final file = File('lib/presentation/setup/setup_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("await _profilesRepo.loadProfiles();", "await _profilesRepo.loadSavedPlayers();");
  content = content.replaceAll("setState(() {\n      _savedPlayers = profiles.map((p) => p.name).toList();\n    });", "setState(() {\n      _savedPlayers = profiles;\n    });");
  
  content = content.replaceAll("ref.read(gameOrchestratorProvider.notifier).removePlayer(index);", "final players = ref.read(gameOrchestratorProvider).players;\n    ref.read(gameOrchestratorProvider.notifier).removePlayer(players[index].id);");
  content = content.replaceAll("onRemove(index)", "onRemove(index)");
  
  file.writeAsStringSync(content);
}