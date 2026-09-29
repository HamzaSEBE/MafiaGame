import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  // Remove onBackStep from GamePopScope
  content = content.replaceAll(RegExp(r'onBackStep:\s*_stepIndex\s*>\s*0\s*\?\s*_goBack\s*:\s*null,'), '');
  
  // Add leading to AppBar
  // Since there are multiple AppBars in night_screen, we need to be careful.
  content = content.replaceAll(
    'automaticallyImplyLeading: false,',
    '''automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(_stepIndex > 0 ? Icons.undo : Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              if (_stepIndex > 0) {
                _goBack();
              } else {
                Navigator.maybePop(context);
              }
            },
          ),'''
  );

  file.writeAsStringSync(content);
}