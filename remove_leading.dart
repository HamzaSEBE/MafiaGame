import 'dart:io';

void removeLeading(String path) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  content = content.replaceAll(RegExp(r'\s*leading: IconButton\(\s*icon: const Icon\(Icons\.arrow_back_ios_new, color: Colors\.white\),\s*onPressed: \(\) => Navigator\.maybePop\(context\),\s*\),'), '');
  
  file.writeAsStringSync(content);
}

void main() {
  removeLeading('lib/presentation/day/day_screen.dart');
  removeLeading('lib/presentation/voting/voting_screen.dart');
  removeLeading('lib/presentation/reveal/role_reveal_screen.dart');
  removeLeading('lib/presentation/night/night_summary_screen.dart');
}