import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  // Need to replace the PopScope with GamePopScope
  // First, add the import if missing
  if (!content.contains('package:mafia_nightfall/presentation/widgets/game_pop_scope.dart')) {
    content = content.replaceFirst(
      "import 'package:flutter/material.dart';",
      "import 'package:flutter/material.dart';\nimport 'package:mafia_nightfall/presentation/widgets/game_pop_scope.dart';"
    );
  }

  // Find the exact PopScope block
  final popScopeRegex = RegExp(r'return PopScope\([\s\S]*?child: Builder\(builder: \(context\) \{');
  
  content = content.replaceAll(popScopeRegex, 'return GamePopScope(\n      onBackStep: _stepIndex > 0 ? _goBack : null,\n      child: Builder(builder: (context) {');
  
  file.writeAsStringSync(content);
}