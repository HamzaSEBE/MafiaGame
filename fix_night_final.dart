import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  // Remove onBackStep from GamePopScope
  content = content.replaceAll(RegExp(r'onBackStep:\s*_stepIndex\s*>\s*0\s*\?\s*_goBack\s*:\s*null,'), '');
  
  // Replace the leading
  final startIdx = content.indexOf('leading: _stepIndex > 0');
  if (startIdx != -1) {
    final endIdx = content.indexOf(': null,', startIdx);
    if (endIdx != -1) {
      final toReplace = content.substring(startIdx, endIdx + 7);
      content = content.replaceFirst(toReplace, 'leading: IconButton(icon: Icon(_stepIndex > 0 ? Icons.undo : Icons.exit_to_app, color: Colors.white), onPressed: () { if (_stepIndex > 0) { _goBack(); } else { Navigator.maybePop(context); } }),');
    }
  }

  file.writeAsStringSync(content);
}