import 'dart:io';

void main() {
  final file = File('lib/presentation/voting/voting_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "ref.read(gameOrchestratorProvider.notifier).resolveDay(executedId: executedId);",
    "ref.read(gameOrchestratorProvider.notifier).submitFinalVotes(_votes);\n              ref.read(gameOrchestratorProvider.notifier).resolveVote();"
  );
  
  file.writeAsStringSync(content);
}