import 'dart:io';

void main() {
  final file = File('lib/presentation/history/game_history_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('newspaper_widget.dart')) {
    content = "import 'package:mafia_nightfall/presentation/widgets/newspaper_widget.dart';\n" + content;
  }
  
  // Replace the custom dialog with NewspaperWidget
  final oldDialogStart = "void _showNewspaperDialog(BuildContext context, String? text) {";
  final oldDialogEnd = "  @override\n  Widget build(BuildContext context) {";
  
  final newDialog = """
  void _showNewspaperDialog(BuildContext context, String? text) {
    if (text == null || text.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NewspaperWidget(narrative: text),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق الجريدة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {""";
  
  final startIndex = content.indexOf(oldDialogStart);
  final endIndex = content.indexOf(oldDialogEnd) + oldDialogEnd.length;
  
  content = content.replaceRange(startIndex, endIndex, newDialog);
  
  // Also remove the old _buildRichText function to clean up
  final richTextStart = "Widget _buildRichText(String text) {";
  final richTextEnd = "void _showNewspaperDialog";
  if (content.contains(richTextStart)) {
    final startIdx = content.indexOf(richTextStart);
    final endIdx = content.indexOf(richTextEnd);
    content = content.replaceRange(startIdx, endIdx, "");
  }

  file.writeAsStringSync(content);
}