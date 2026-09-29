import 'dart:io';

void main() {
  void fixFile(String path, Map<RegExp, String> replacements) {
    final file = File(path);
    var content = file.readAsStringSync();
    
    if (content.contains("const AnimatedBackground(),")) {
      content = content.replaceAll(
        "const AnimatedBackground(),", 
        "Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: [Color(0xFF261D15), Color(0xFF130E0A), Color(0xFF07070B)])))),\n          const AnimatedBackground(),"
      );
    }
    
    // Convert to Glassmorphism
    content = content.replaceAll("backgroundColor: AppTheme.background", "backgroundColor: const Color(0xFF07070B)");
    content = content.replaceAll("color: AppTheme.surface,", "color: const Color(0xFF1E1E24),");
    content = content.replaceAll("color: AppTheme.surfaceHigh,", "color: Colors.white.withValues(alpha: 0.05),");
    content = content.replaceAll("color: isSelected ? AppTheme.warning.withValues(alpha: 0.1) : AppTheme.surfaceHigh,", "color: isSelected ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),");
    
    // Execute all regex carefully
    for (var entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    file.writeAsStringSync(content);
  }

  // Voting
  fixFile('lib/presentation/voting/voting_screen.dart', {
    RegExp(r"Text\('.*\$\{voter\.name\}OY',\s*style: const TextStyle\(fontSize: 20,\s*fontFamily: 'Cairo',\s*fontWeight: FontWeight.bold,\s*color: AppTheme.warning\)\)"): 
        "Text('لمن سيصوت \${voter.name}؟', style: const TextStyle(fontSize: 20, fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.warning))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(color: AppTheme.warning,\s*fontSize: 12\)\)"): 
        "const Text('تغيير التصويت', style: TextStyle(color: AppTheme.warning, fontSize: 12))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(fontSize: 12\)\)"): 
        "const Text('تأكيد الإعدام', style: TextStyle(fontSize: 12))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(fontSize: 20,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"):
        "const Text('حساب الأصوات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(color: AppTheme.textSecondary,\s*fontSize: 12\)\)"):
        "const Text('بعد انتهاء الدفاع:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(fontFamily: 'Cairo'\)\)"):
        "const Text('ابدأ المؤقت', style: TextStyle(fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(fontFamily: 'Cairo',\s*color: AppTheme.textSecondary\)\)"):
        "const Text('ثانية للدفاع عن نفسه', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary))",
    RegExp(r"Text\(\s*'.*'\,\s*style: const TextStyle\(color: AppTheme.textSecondary,\s*fontSize: 14,\s*fontFamily: 'Cairo'\),\s*\)"):
        "Text('حصل على \${widget.votesCount} أصوات', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*!',\s*style: TextStyle\(color: AppTheme.error,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\),\s*textAlign: TextAlign.center\)"):
        "const Text('محاكمة المافيا!', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontFamily: 'Cairo'), textAlign: TextAlign.center)",
    RegExp(r"const Text\('.*!',\s*style: TextStyle\(color: AppTheme.textPrimary,\s*fontFamily: 'Cairo'\)\)"):
        "const Text('نتيجة التصويت!', style: TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo'))",
    RegExp(r"Text\('.*!',\s*style: const TextStyle\(color: AppTheme.death,\s*fontFamily: 'Cairo',\s*fontSize: 18,\s*fontWeight: FontWeight.bold\)\)"):
        "Text('تم إعدام \${eliminated.name}!', style: const TextStyle(color: AppTheme.death, fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold))",
    RegExp(r"Text\('.* \$\{AppTheme.roleArabicName\(eliminated\.role\)\}',\s*style: TextStyle\(color: AppTheme.roleColor\(eliminated.role\),\s*fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"):
        "Text('كان: \${AppTheme.roleArabicName(eliminated.role)}', style: TextStyle(color: AppTheme.roleColor(eliminated.role), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(color: AppTheme.textPrimary,\s*fontFamily: 'Cairo',\s*fontSize: 18,\s*fontWeight: FontWeight.bold\)\)"):
        "const Text('لم يتم التصويت ضد أحد', style: TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(color: Colors.white,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"):
        "const Text('متابعة إلى الليل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))",
  });
  
  // Night Summary
  fixFile('lib/presentation/night/night_summary_screen.dart', {
    RegExp(r"const Text\('.*',\s*style: TextStyle\(color: Colors.white,\s*fontFamily: 'Cairo'\)\)"):
        "const Text('ملخص الليل (للحكم فقط)', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*!',\s*style: TextStyle\(color: AppTheme.specialAction,\s*fontFamily: 'Cairo'\)\)"):
        "const Text('رد فعل المواطن الشجاع!', style: TextStyle(color: AppTheme.specialAction, fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*:',\s*style: TextStyle\(fontFamily: 'Cairo'\)\)"):
        "const Text('بما أنك قُتلت، يمكنك أخذ لاعب معك:', style: TextStyle(fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(color: AppTheme.textSecondary\)\)"):
        "const Text('تخطي', style: TextStyle(color: AppTheme.textSecondary))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(color: Colors.white,\s*fontFamily: 'Cairo'\)\)"):
        "const Text('تأكيد واغتيال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*!',\s*style: TextStyle\(color: AppTheme.death,\s*fontFamily: 'Cairo'\),\s*textAlign: TextAlign.center\)"):
        "const Text('ضحية المواطن الشجاع!', style: TextStyle(color: AppTheme.death, fontFamily: 'Cairo'), textAlign: TextAlign.center)",
    RegExp(r"Text\('.*: \$\{AppTheme.roleArabicName\(target.role\)\}',\s*style: TextStyle\(color: AppTheme.roleColor\(target.role\),\s*fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"):
        "Text('كان: \${AppTheme.roleArabicName(target.role)}', style: TextStyle(color: AppTheme.roleColor(target.role), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(fontSize: 16,\s*fontWeight: FontWeight.bold,\s*color: Colors.white\)\)"):
        "const Text('متابعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))",
    RegExp(r"const Text\(\s*'.*:',\s*style: TextStyle\(fontSize: 22,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\),\s*textAlign: TextAlign.center,\s*\)"):
        "const Text('انتهت الليلة، وإليك ما حدث:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'), textAlign: TextAlign.center)",
    RegExp(r"const Text\('.*',\s*style: TextStyle\(color: AppTheme.error,\s*fontSize: 16,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"):
        "const Text('ضحية الليل (تم اغتياله):', style: TextStyle(color: AppTheme.error, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))",
    RegExp(r"Text\(\s*state.phase == Phase.triggeredAbility \? '.*!' : '.*',\s*style: const TextStyle\(fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\s*\)"):
        "Text(state.phase == Phase.triggeredAbility ? 'رد فعل المواطن الشجاع!' : 'بدء النهار', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))",
    RegExp(r"const Text\('.*!',\s*style: TextStyle\(color: AppTheme.success,\s*fontSize: 18,\s*fontWeight: FontWeight.bold,\s*fontFamily: 'Cairo'\)\)"):
        "const Text('تمت حماية الهدف بنجاح! لم يُقتل أحد.', style: TextStyle(color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))",
  });
}