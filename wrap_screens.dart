import 'dart:io';

void wrapScreen(String path) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  if (content.contains('GamePopScope')) return;
  
  content = content.replaceFirst(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';"
  );

  final scaffoldIndex = content.indexOf('return Scaffold(');
  if (scaffoldIndex == -1) return;
  
  int braceCount = 1;
  int endIndex = -1;
  final startIndex = scaffoldIndex + 'return Scaffold('.length;
  
  for (int i = startIndex; i < content.length; i++) {
    if (content[i] == '(') braceCount++;
    if (content[i] == ')') braceCount--;
    if (braceCount == 0) {
      endIndex = i;
      break;
    }
  }
  
  if (endIndex != -1) {
    content = content.substring(0, endIndex + 1) + ')' + content.substring(endIndex + 1);
  }
  
  content = content.replaceFirst('return Scaffold(', 'return GamePopScope(child: Scaffold(');
  file.writeAsStringSync(content);
}

void main() {
  wrapScreen('lib/presentation/day/day_screen.dart');
  wrapScreen('lib/presentation/voting/voting_screen.dart');
  wrapScreen('lib/presentation/reveal/role_reveal_screen.dart');
  wrapScreen('lib/presentation/night/night_summary_screen.dart');
}