import 'dart:io';

void main() {
  final oldFile = File('c:/Users/Hamza/Documents/Real-Projects/MafiaGameRepo/voting_screen_9166c35.dart');
  final currentFile = File('lib/presentation/voting/voting_screen.dart');
  
  var oldContent = oldFile.readAsStringSync();
  var currentContent = currentFile.readAsStringSync();
  
  // Extract _showVotePicker from oldContent
  final votePickerStart = oldContent.indexOf("void _showVotePicker(Player voter) {");
  final votePickerEnd = oldContent.indexOf("void _confirmExecution() {", votePickerStart);
  final votePickerCode = oldContent.substring(votePickerStart, votePickerEnd);
  
  // Extract build from oldContent
  final buildStart = oldContent.indexOf("Widget build(BuildContext context) {");
  final buildEnd = oldContent.indexOf("}\n}\n\nclass _DefenseTimerDialog", buildStart) + 3;
  var buildCode = oldContent.substring(buildStart, buildEnd);
  
  // Inject the skip button into the AppBar of buildCode
  final appbarStart = buildCode.indexOf("actions: [");
  buildCode = buildCode.replaceRange(appbarStart, appbarStart + 10, "actions: [\n            TextButton(\n              onPressed: () {\n                ref.read(gameOrchestratorProvider.notifier).skipElimination();\n                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const NightScreen()), (route) => false);\n              },\n              child: const Text('تخطي التصويت', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),\n            ),");

  // In buildCode, replace _confirmExecution with _calculateLocalResult
  buildCode = buildCode.replaceAll("_confirmExecution", "_calculateLocalResult");
  
  // Now replace in currentContent
  final curVotePickerStart = currentContent.indexOf("void _showVotePicker(Player voter) {");
  final curVotePickerEnd = currentContent.indexOf("void _calculateLocalResult() {", curVotePickerStart);
  
  final curBuildStart = currentContent.indexOf("Widget build(BuildContext context) {");
  final curBuildEnd = currentContent.indexOf("}\n}\n\nclass _DefenseTimerDialog", curBuildStart) + 3;
  
  var newContent = currentContent.replaceRange(curBuildStart, curBuildEnd, buildCode);
  
  // After replacing build, the curVotePickerStart might have changed if we didn't do it top-down. 
  // It's better to replace VotePicker first.
}