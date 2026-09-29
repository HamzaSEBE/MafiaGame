import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_summary_screen.dart');
  var content = file.readAsStringSync();
  
  // Scaffold styling
  content = content.replaceAll("backgroundColor: AppTheme.background", "backgroundColor: const Color(0xFF07070B)");
  content = content.replaceAll("body: Padding(", "body: Stack(children: [Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.5, colors: [Color(0xFF130E0A), Color(0xFF07070B)])))), Padding(");
  final endLast = content.lastIndexOf("));\n  }");
  if (endLast != -1) {
    content = content.replaceRange(endLast, endLast + 7, "],)));\n  }");
  }

  // Cards
  content = content.replaceAll("color: AppTheme.surfaceHigh", "color: Colors.white.withValues(alpha: 0.05)");
  content = content.replaceAll("color: AppTheme.surface", "color: const Color(0xFF1E1E24)");
  
  file.writeAsStringSync(content);
}