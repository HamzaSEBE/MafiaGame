import 'dart:io';

void main() {
  final file = File('lib/presentation/day/day_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("color: AppTheme.textPrimary", "color: Colors.white");
  content = content.replaceAll("color: AppTheme.textSecondary", "color: Colors.white70");
  content = content.replaceAll("color: AppTheme.warning", "color: Colors.orangeAccent");
  content = content.replaceAll("color: AppTheme.error", "color: Colors.redAccent");
  content = content.replaceAll("color: AppTheme.accent", "color: Colors.orangeAccent");
  
  content = content.replaceAll("AppTheme.surfaceHigh", "Colors.white.withValues(alpha: 0.05)");
  content = content.replaceAll("AppTheme.surface", "const Color(0xFF1E1E24)");
  
  file.writeAsStringSync(content);
}