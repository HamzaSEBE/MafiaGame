import 'dart:io';

void fixFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();
  
  // Universal UI upgrades
  content = content.replaceAll("body: Padding(", "body: Stack(children: [Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: [Color(0xFF261D15), Color(0xFF130E0A), Color(0xFF07070B)])))), Padding(");
  final endLast = content.lastIndexOf("));\n  }");
  if (endLast != -1 && content.contains("Positioned.fill(child:")) {
    content = content.replaceRange(endLast, endLast + 7, "],)));\n  }");
  }
  
  content = content.replaceAll("backgroundColor: AppTheme.background", "backgroundColor: const Color(0xFF07070B)");
  content = content.replaceAll("color: AppTheme.surfaceHigh", "color: Colors.white.withValues(alpha: 0.05)");
  content = content.replaceAll("color: AppTheme.surface", "color: const Color(0xFF1E1E24)");
  content = content.replaceAll("color: isSelected ? AppTheme.warning.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),", "color: isSelected ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),");
  
  // Replace all Arabic garbled text using simple regex that ignores the garbled part
  content = content.replaceAll(RegExp(r"title: const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.error,\s*fontFamily: 'Cairo'\)\)"), "title: const Text('إنهاء اللعبة؟', style: TextStyle(color: AppTheme.error, fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"content: const Text\('[^']+',\s*style: TextStyle\(fontFamily: 'Cairo'\)\)"), "content: const Text('هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟', style: TextStyle(fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"child: const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textSecondary,\s*fontFamily: 'Cairo'\)\)"), "child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'))");
  content = content.replaceAll(RegExp(r"child: const Text\('[^']+',\s*style: TextStyle\(fontFamily: 'Cairo'\)\)"), "child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo'))");
  
  // Voting Screen specifically
  if (path.contains("voting_screen")) {
    content = content.replaceAll(RegExp(r"title: const Text\('[^']+',\s*style: TextStyle\(fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "title: const Text('قاعة المحكمة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 24,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "const Text('حان وقت التصويت', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textSecondary,\s*fontFamily: 'Cairo'\)\)"), "const Text('اضغط على اسم اللاعب لاختيار من سيصوت ضده', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'))");
    
    content = content.replaceAll(RegExp(r"Text\('[^']+\$\{voter\.name\}OY',\s*style: const TextStyle\(fontSize: 20,\s*fontFamily: 'Cairo',\s*fontWeight: FontWeight.bold,\s*color: AppTheme.warning\)\)"), "Text('لمن سيصوت \${voter.name}؟', style: const TextStyle(fontSize: 20, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.warning))");
    
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.error,\s*fontSize: 10,\s*fontFamily: 'Cairo',\s*height: 1\)\)"), "const Text('صوت', style: TextStyle(color: AppTheme.error, fontSize: 10, fontFamily: 'Cairo', height: 1))");
    
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 20,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "const Text('حساب الأصوات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))");
    
    // Dialog titles
    content = content.replaceAll(RegExp(r"title: const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.error,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\),\s*textAlign: TextAlign.center\)"), "title: const Text('محاكمة المافيا!', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontFamily: 'Cairo'), textAlign: TextAlign.center)");
    content = content.replaceAll(RegExp(r"title: const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textPrimary,\s*fontFamily: 'Cairo'\)\)"), "title: const Text('نتيجة التصويت!', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))");
    
    // "صوت لـ"
    content = content.replaceAll(RegExp(r"Text\('[^']+',\s*style: const TextStyle\(color: AppTheme.error,\s*fontSize: 12,\s*fontFamily: 'Cairo'\)\)"), "Text('صوت لـ', style: const TextStyle(color: AppTheme.error, fontSize: 12, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"Text\('[^']+',\s*style: const TextStyle\(color: AppTheme.textSecondary,\s*fontSize: 12,\s*fontFamily: 'Cairo'\)\)"), "Text('لم يصوت', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo'))");
    
    // Votes Count
    content = content.replaceAll(RegExp(r"Text\(\s*'[^']+\$\{widget\.votesCount\}[^']+',\s*style: const TextStyle\(color: AppTheme.textSecondary,\s*fontSize: 14,\s*fontFamily: 'Cairo'\),\s*\)"), "Text('حصل على \${widget.votesCount} أصوات', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontFamily: 'Cairo'))");
    
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textSecondary,\s*fontSize: 12\)\)"), "const Text('بعد انتهاء الدفاع:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.warning,\s*fontSize: 12\)\)"), "const Text('تغيير التصويت', style: TextStyle(color: AppTheme.warning, fontSize: 12))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 12\)\)"), "const Text('تأكيد الإعدام', style: TextStyle(fontSize: 12))");
    content = content.replaceAll(RegExp(r"Text\('[^']+\$\{eliminated\.name\}!',\s*style: const TextStyle\(color: AppTheme.death,\s*fontFamily: 'Cairo',\s*fontSize: 18,\s*fontWeight: FontWeight.bold\)\)"), "Text('تم إعدام \${eliminated.name}!', style: const TextStyle(color: AppTheme.death, fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold))");
    content = content.replaceAll(RegExp(r"Text\('[^']+\$\{AppTheme\.roleArabicName\(eliminated\.role\)\}',\s*style: TextStyle\(color: AppTheme.roleColor\(eliminated\.role\),\s*fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "Text('كان: \${AppTheme.roleArabicName(eliminated.role)}', style: TextStyle(color: AppTheme.roleColor(eliminated.role), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: Colors.white,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "const Text('متابعة إلى الليلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textPrimary,\s*fontFamily: 'Cairo',\s*fontSize: 18,\s*fontWeight: FontWeight.bold\)\)"), "const Text('لم يتم التصويت ضد أحد', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold))");
  }
  
  // Night Summary specifically
  if (path.contains("night_summary_screen")) {
    content = content.replaceAll(RegExp(r"title: const Text\('[^']+'\)"), "title: const Text('ملخص الليلة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\(\s*'[^']+',\s*style: TextStyle\(fontSize: 22,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\),\s*textAlign: TextAlign.center,\s*\)"), "const Text('انتهت الليلة، وإليك ما حدث:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white), textAlign: TextAlign.center)");
    content = content.replaceAll(RegExp(r"Text\('[^']+',\s*style: TextStyle\(color: AppTheme.success,\s*fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "Text('نجحت الحماية! لم يُقتل أحد.', style: TextStyle(color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.error,\s*fontSize: 16,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "const Text('ضحية الليل (تم اغتياله):', style: TextStyle(color: AppTheme.error, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"title: '[^']+',\s*names:"), "title: 'تم إسكاتهم:', names:");
    content = content.replaceAll(RegExp(r"Text\(\s*state\.phase == Phase\.triggeredAbility \? '[^']+' : '[^']+',\s*style: const TextStyle\(fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\s*\)"), "Text(state.phase == Phase.triggeredAbility ? 'رد فعل المواطن الشجاع!' : 'بدء النهار', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.black))");
    content = content.replaceAll(RegExp(r"Text\('[^']+',\s*style: TextStyle\(color: AppTheme.specialAction,\s*fontFamily: 'Cairo'\)\)"), "Text('رد فعل المواطن الشجاع!', style: TextStyle(color: AppTheme.specialAction, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontFamily: 'Cairo'\)\)"), "const Text('بما أنك قُتلت، يمكنك أخذ لاعب معك:', style: TextStyle(fontFamily: 'Cairo', color: Colors.white))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textSecondary\)\)"), "const Text('تخطي', style: TextStyle(color: AppTheme.textSecondary))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: Colors.white,\s*fontFamily: 'Cairo'\)\)"), "const Text('تأكيد واغتيال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.death,\s*fontFamily: 'Cairo'\),\s*textAlign: TextAlign.center\)"), "const Text('ضحية المواطن الشجاع!', style: TextStyle(color: AppTheme.death, fontFamily: 'Cairo'), textAlign: TextAlign.center)");
    content = content.replaceAll(RegExp(r"Text\('[^']+\$\{AppTheme\.roleArabicName\(target\.role\)\}',\s*style: TextStyle\(color: AppTheme.roleColor\(target\.role\),\s*fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "Text('كان: \${AppTheme.roleArabicName(target.role)}', style: TextStyle(color: AppTheme.roleColor(target.role), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 16,\s*fontWeight: FontWeight.bold,\s*color: Colors.white\)\)"), "const Text('متابعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))");
  }
  
  // Day Screen specifically
  if (path.contains("day_screen")) {
    content = content.replaceAll(RegExp(r"Text\('[^']+\$round',\s*style: const TextStyle\(fontWeight: FontWeight.bold\)\)"), "Text('النهار \$round', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 16,\s*fontFamily: 'Cairo'\)\)"), "const Text('تشاوروا وتناقشوا من القاتل!', style: TextStyle(fontSize: 16, fontFamily: 'Cairo', color: Colors.white))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.textSecondary,\s*fontSize: 16,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "const Text('الأحياء:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.mafiaPrimary,\s*fontSize: 11,\s*fontFamily: 'Cairo'\)\)"), "const Text('تم إسكاته', style: TextStyle(color: AppTheme.mafiaPrimary, fontSize: 11, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(color: AppTheme.error,\s*fontSize: 16,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "const Text('الأموات:', style: TextStyle(color: AppTheme.error, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))");
    content = content.replaceAll(RegExp(r"const Text\('[^']+',\s*style: TextStyle\(fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"), "const Text('الانتقال للتصويت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.black))");
  }
  
  file.writeAsStringSync(content);
}

void main() {
  fixFile('lib/presentation/voting/voting_screen.dart');
  fixFile('lib/presentation/night/night_summary_screen.dart');
  fixFile('lib/presentation/day/day_screen.dart');
}