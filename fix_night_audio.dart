import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  final replacement = '''
                Navigator.pop(ctx);
                if (step.eventType == EventType.assassination) {
                  ref.read(audioManagerProvider).playKill();
                } else if (step.eventType == EventType.protection) {
                  ref.read(audioManagerProvider).playProtect();
                } else {
                  ref.read(audioManagerProvider).playClick();
                }
                ref.read(gameOrchestratorProvider.notifier).submitNightAction(
''';
  
  content = content.replaceFirst('Navigator.pop(ctx);\n                ref.read(gameOrchestratorProvider.notifier).submitNightAction(', replacement);
  
  file.writeAsStringSync(content);
}