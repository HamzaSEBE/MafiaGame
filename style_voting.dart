import 'dart:io';

void main() {
  final file = File('lib/presentation/voting/voting_screen.dart');
  var content = file.readAsStringSync();
  
  // Style cards
  content = content.replaceAll(
    "color: isSelected ? AppTheme.warning.withValues(alpha: 0.1) : AppTheme.surfaceHigh,",
    "color: isSelected ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),"
  );
  content = content.replaceAll(
    "border: Border.all(color: isSelected ? AppTheme.warning : Colors.transparent, width: 2),",
    "border: Border.all(color: isSelected ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.1), width: 2),"
  );
  
  // Style text
  content = content.replaceAll("color: AppTheme.textPrimary", "color: Colors.white");
  content = content.replaceAll("color: AppTheme.textSecondary", "color: Colors.white70");
  content = content.replaceAll("color: AppTheme.warning", "color: Colors.orangeAccent");
  content = content.replaceAll("color: AppTheme.error", "color: Colors.redAccent");
  content = content.replaceAll("color: AppTheme.success", "color: Colors.greenAccent");
  
  // AppTheme colors fallback
  content = content.replaceAll("AppTheme.surface", "const Color(0xFF1E1E24)");
  
  file.writeAsStringSync(content);
}