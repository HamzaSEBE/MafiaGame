import 'dart:io';
void main() {
  final file = File('lib/presentation/night/night_summary_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("],)));\n  }", "));\n  }"); // Revert first
  content = content.replaceAll("    ));\n  }", "      ],\n    )));\n  }");
  file.writeAsStringSync(content);
}