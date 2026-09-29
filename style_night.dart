import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("color: AppTheme.surfaceHigh,", "color: Colors.white.withValues(alpha: 0.1),");
  content = content.replaceAll("color: AppTheme.surface,", "color: Colors.white.withValues(alpha: 0.05),");
  content = content.replaceAll("AppTheme.surface", "const Color(0xFF1E1E24)");
  content = content.replaceAll("color: AppTheme.textPrimary", "color: Colors.white");
  content = content.replaceAll("color: AppTheme.textSecondary", "color: Colors.white70");
  content = content.replaceAll("color: AppTheme.error", "color: Colors.redAccent");
  content = content.replaceAll("color: AppTheme.success", "color: Colors.greenAccent");
  
  file.writeAsStringSync(content);
}