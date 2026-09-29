import 'dart:io';

void closeGamePopScope(String path) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  // To safely append a `)` to the GamePopScope wrapping, we can find the end of `Widget build(BuildContext context)` block.
  // A much simpler way: just replace `return GamePopScope(child: Scaffold(`... wait, GamePopScope(child: Scaffold(...) -> the closing for GamePopScope should be `)` right where Scaffold's closing `);` is.
  // Actually, since I replaced `return Scaffold(` with `return GamePopScope(child: Scaffold(`, I just need to replace the `);` that belongs to `Scaffold` with `));`
  // But how to find it? I can just use the Regex for `);` at the end of the build method.
  
  final buildIndex = content.indexOf('Widget build(BuildContext context) {');
  if (buildIndex == -1) return;
  
  final startIndex = buildIndex + 'Widget build(BuildContext context) {'.length;
  
  int braceCount = 1;
  int endIndex = -1;
  for (int i = startIndex; i < content.length; i++) {
    if (content[i] == '{') braceCount++;
    if (content[i] == '}') braceCount--;
    if (braceCount == 0) {
      endIndex = i;
      break;
    }
  }
  
  // In the buildBody, find the last `);` and replace it with `));`
  var buildBody = content.substring(startIndex, endIndex);
  if (!buildBody.trimRight().endsWith('));')) {
    final lastSemi = buildBody.lastIndexOf(';');
    if (lastSemi != -1) {
      final before = buildBody.substring(0, lastSemi);
      final after = buildBody.substring(lastSemi);
      // Wait, if it ends with `);`, we change it to `));`
      final lastParenSemi = buildBody.lastIndexOf(');');
      if (lastParenSemi != -1 && lastParenSemi > lastSemi - 5) {
         buildBody = buildBody.substring(0, lastParenSemi) + '));' + buildBody.substring(lastParenSemi + 2);
      }
    }
    content = content.replaceRange(startIndex, endIndex, buildBody);
    file.writeAsStringSync(content);
  }
}

void main() {
  closeGamePopScope('lib/presentation/day/day_screen.dart');
  closeGamePopScope('lib/presentation/voting/voting_screen.dart');
  closeGamePopScope('lib/presentation/reveal/role_reveal_screen.dart');
  closeGamePopScope('lib/presentation/night/night_summary_screen.dart');
}