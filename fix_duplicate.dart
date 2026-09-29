import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  final regex = RegExp(r'leading:\s*_stepIndex\s*>\s*0[\s\S]*?\:\s*null,');
  final matches = regex.allMatches(content).toList();
  
  if (matches.length > 1) {
    content = content.replaceRange(matches[1].start, matches[1].end, '');
    file.writeAsStringSync(content);
    print('Fixed duplicate leading!');
  }
}