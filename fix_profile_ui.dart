import 'dart:io';

void main() {
  final file = File('lib/presentation/profile/profile_screen.dart');
  var content = file.readAsStringSync();
  
  // Replace scaffold background
  content = content.replaceAll("backgroundColor: AppTheme.background,", "backgroundColor: const Color(0xFF07070B),");
  
  // Find AppBar
  final appBarRegex = RegExp(r'appBar: AppBar\(.*?\),', dotAll: true);
  content = content.replaceAll(appBarRegex, "appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),");
  
  // Add gradient background
  content = content.replaceAll("body: _isLoading", "body: Stack(children: [ Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.5, colors: [Color(0xFF261D15), Color(0xFF130E0A), Color(0xFF07070B)])))), _isLoading");
  
  // Replace stats cards with glassmorphism
  content = content.replaceAll("Card(\n      color: AppTheme.surface,", "Container(\n      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),");
  content = content.replaceAll("Card(\n                            color: AppTheme.surface,", "Container(\n                            padding: const EdgeInsets.all(16),\n                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),");
  
  // Close the stack
  final lastIndex = content.lastIndexOf(");");
  if (lastIndex != -1 && content.contains('Stack(children')) {
    content = content.replaceRange(lastIndex, lastIndex + 2, "],);");
  }

  file.writeAsStringSync(content);
}