import 'dart:io';

void main() {
  final oldFile = File('c:/Users/Hamza/Documents/Real-Projects/MafiaGameRepo/voting_screen_9166c35.dart');
  final currentFile = File('lib/presentation/voting/voting_screen.dart');
  
  var oldContent = oldFile.readAsStringSync();
  var currentContent = currentFile.readAsStringSync();
  
  // 1. Extract _showVotePicker from 9166c35
  final vpStartOld = oldContent.indexOf("void _showVotePicker(Player voter) {");
  final vpEndOld = oldContent.indexOf("void _confirmExecution() {", vpStartOld);
  final vpCode = oldContent.substring(vpStartOld, vpEndOld);
  
  // 2. Extract build from 9166c35
  final bStartOld = oldContent.indexOf("Widget build(BuildContext context) {");
  final bEndOld = oldContent.indexOf("class _DefenseTimerDialog", bStartOld);
  var bCode = oldContent.substring(bStartOld, bEndOld);
  
  // Modify bCode to include Skip Voting
  bCode = bCode.replaceAll("actions: [", "actions: [\n            TextButton(\n              onPressed: () {\n                ref.read(gameOrchestratorProvider.notifier).skipElimination();\n                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const NightScreen()), (route) => false);\n              },\n              child: const Text('تخطي التصويت', style: TextStyle(color: Colors.white70, fontFamily: 'Cairo')),\n            ),");
  
  // Modify bCode to point to _calculateLocalResult instead of _confirmExecution
  bCode = bCode.replaceAll("_confirmExecution", "_calculateLocalResult");
  
  // 3. Replace in currentContent
  // Replace build first (since it's at the bottom)
  final bStartCur = currentContent.indexOf("Widget build(BuildContext context) {");
  final bEndCur = currentContent.indexOf("class _DefenseTimerDialog", bStartCur);
  currentContent = currentContent.replaceRange(bStartCur, bEndCur, bCode);
  
  // Replace _showVotePicker
  final vpStartCur = currentContent.indexOf("void _showVotePicker(Player voter) {");
  final vpEndCur = currentContent.indexOf("void _calculateLocalResult() {", vpStartCur);
  currentContent = currentContent.replaceRange(vpStartCur, vpEndCur, vpCode);
  
  currentFile.writeAsStringSync(currentContent);
}