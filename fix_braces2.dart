import 'dart:io';
void main() {
  final file = File('lib/presentation/night/night_summary_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("    ));\r\n  }", "      ],\n    )));\n  }");
  content = content.replaceAll("    ));\n  }", "      ],\n    )));\n  }");
  file.writeAsStringSync(content);
}