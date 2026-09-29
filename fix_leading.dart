import 'dart:io';

void replaceLeading(String path, bool isNight) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  if (isNight) {
    content = content.replaceAll(RegExp(r'onBackStep:\s*_stepIndex\s*>\s*0\s*\?\s*_goBack\s*:\s*null,'), '');
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
  } else {
    content = content.replaceAll(
      'automaticallyImplyLeading: false,',
      '''automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),'''
    );
  }
  file.writeAsStringSync(content);
}

void main() {
  replaceLeading('lib/presentation/day/day_screen.dart', false);
  replaceLeading('lib/presentation/voting/voting_screen.dart', false);
  replaceLeading('lib/presentation/reveal/role_reveal_screen.dart', false);
  replaceLeading('lib/presentation/night/night_summary_screen.dart', false);
  replaceLeading('lib/presentation/night/night_screen.dart', true);
}