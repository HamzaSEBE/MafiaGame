import 'dart:io';

void main() {
  void fixHigh(String path) {
    final file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    content = content.replaceAll("const Color(0xFF1E1E24)High", "Colors.white.withValues(alpha: 0.05)");
    content = content.replaceAll("Colors.white.withValues(alpha: 0.05),High", "Colors.white.withValues(alpha: 0.05)");
    file.writeAsStringSync(content);
  }
  
  fixHigh('lib/presentation/night/night_screen.dart');
  fixHigh('lib/presentation/voting/voting_screen.dart');
  fixHigh('lib/presentation/day/day_screen.dart');
}