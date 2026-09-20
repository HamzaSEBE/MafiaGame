import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  // Remove onBackStep
  content = content.replaceAll(RegExp(r'onBackStep:\s*_stepIndex\s*>\s*0\s*\?\s*_goBack\s*:\s*null,'), '');
  
  // Add Undo button to AppBar
  content = content.replaceAll(
    'elevation: 0,',
    'elevation: 0,\n        leading: _stepIndex > 0 ? IconButton(icon: const Icon(Icons.undo, color: Colors.white), onPressed: _goBack) : null,'
  );

  file.writeAsStringSync(content);
}