import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  if (content.contains("const AnimatedBackground(),")) {
    content = content.replaceAll(
      "const AnimatedBackground(),", 
      "Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: [Color(0xFF261D15), Color(0xFF130E0A), Color(0xFF07070B)])))),\n          const AnimatedBackground(),"
    );
  }
  
  content = content.replaceAll("backgroundColor: AppTheme.background", "backgroundColor: const Color(0xFF07070B)");
  content = content.replaceAll("color: AppTheme.surfaceHigh,", "color: Colors.white.withValues(alpha: 0.1),");
  content = content.replaceAll("color: AppTheme.surface,", "color: Colors.white.withValues(alpha: 0.05),");
  content = content.replaceAll("color: AppTheme.surfaceHigh", "color: Colors.white.withValues(alpha: 0.1)");
  content = content.replaceAll("color: AppTheme.surface", "color: const Color(0xFF1E1E24)");
  
  // Night 1
  content = content.replaceAll(RegExp(r"title: const Text\('[^']+',\s*style: TextStyle\(fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "title: const Text('الليلة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white))");
  content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 22,\s*fontFamily: 'Cairo',\s*height: 1\.8,\s*fontWeight: FontWeight.bold\),\s*textAlign: TextAlign.center\)"), "const Text('بصوت عالي قل:\\n\\nالكل يغمض عينيه\\nالمافيا تفتح عينيها\\nالمافيا تغمض\\nالكل يفتح', style: TextStyle(fontSize: 22, fontFamily: 'Cairo', height: 1.8, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)");
  content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "const Text('متابعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.black))");
  
  // AppTheme errors
  content = content.replaceAll(RegExp(r"title: const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.error,\s*fontFamily: 'Cairo'\)\)"), "title: const Text('إنهاء اللعبة؟', style: TextStyle(color: AppTheme.error, fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"content: const Text\('[^']+',\s*style: TextStyle\(fontFamily: 'Cairo'\)\)"), "content: const Text('هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟', style: TextStyle(fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"child: const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textSecondary,\s*fontFamily: 'Cairo'\)\)"), "child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"child: const Text\('[^']+',\s*style: TextStyle\(fontFamily: 'Cairo'\)\)"), "child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo'))");
  
  // Others
  content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.error,\s*fontSize: 12,\s*fontFamily: 'Cairo'\)\)"), "const Text('غير متاح', style: TextStyle(color: AppTheme.error, fontSize: 12, fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.success,\s*fontSize: 12,\s*fontFamily: 'Cairo'\)\)"), "const Text('تلقى حماية', style: TextStyle(color: AppTheme.success, fontSize: 12, fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textSecondary,\s*fontFamily: 'Cairo'\)\)"), "const Text('اختر الهدف:', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 16,\s*fontWeight: FontWeight.bold,\s*color: Colors.white\)\)"), "const Text('تأكيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))");
  
  content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 16,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo',\s*color: Colors.white\)\)"), "const Text('تأكيد الإجراء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.black))");
  content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: Colors.white54,\s*fontFamily: 'Cairo',\s*fontSize: 16\)\)"), "const Text('تخطي الليل', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo', fontSize: 16))");
  
  file.writeAsStringSync(content);
}