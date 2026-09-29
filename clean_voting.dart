import 'dart:io';

void main() {
  final file = File('lib/presentation/voting/voting_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(RegExp(r"Text\('.*\$\{voter\.name\}OY',"), "Text('لمن سيصوت \${voter.name}؟',");
  content = content.replaceAll(RegExp(r"const Text\('.*\^USO.', style:"), "const Text('تصويت', style:");
  content = content.replaceAll(RegExp(r"Text\('O1U.*USOOU\^O.', style:"), "Text('لم يصوت', style:");
  content = content.replaceAll(RegExp(r"const Text\('OO1U,U\% O U,.*U\^USO.', style:"), "const Text('إنهاء التصويت', style:");
  content = content.replaceAll(RegExp(r"const Text\('OU,OO O.', style: TextStyle\(color: AppTheme.error"), "const Text('إلغاء', style: TextStyle(color: AppTheme.error");
  content = content.replaceAll(RegExp(r"const Text\('OOUUSO_ O U,OOOO O.', style:"), "const Text('تأكيد الإعدام', style:");
  content = content.replaceAll(RegExp(r"const Text\('OO-O O O U,O.OU,.', style:"), "const Text('تأكيد الإعدام', style:");
  content = content.replaceAll(RegExp(r"const Text\('OU\+UO O O U,U,O1O.*OcOY', style:"), "const Text('إنهاء اللعبة؟', style:");
  content = content.replaceAll(RegExp(r"const Text\('UU, OU\+O U.OOUO_ OU\+U OOUSO_ OU\+UO O UOU O U,U,O1O.*Oc U\^O U,O1U\^O_Oc U,U,U,O OU.Oc O U,OOUSO3USOcOY', style:"), "const Text('هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟', style:");
  content = content.replaceAll(RegExp(r"const Text\('U\+O1U.OO OU\+UO O.', style:"), "const Text('تأكيد الإنهاء', style:");
  content = content.replaceAll(RegExp(r"title: const Text\('O.U\+U.O O. O U,U,O1O.*OcOY', style:"), "title: const Text('إنهاء اللعبة؟', style:");
  content = content.replaceAll(RegExp(r"content: const Text\('U.U, O.U\+O. U.O.O.U.O_ O.U\+U. O.O.USO_ O.U\+U.O O. U.O.U.U. O U,U,O1O.*Oc U\^O U,O1U\^O_Oc U,U,U,O O.U.Oc O U,O.O.USO3USOcOY', style:"), "content: const Text('هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('O.U,O.O O.', style:"), "child: const Text('إلغاء', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('U\+O1U.OO O.U\+U.O O.', style:"), "child: const Text('تأكيد الإنهاء', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('U\?OO O. U,O.OU\^O.O.', style:"), "child: const Text('تخطي التصويت', style:");
  
  // Defense Dialog
  content = content.replaceAll(RegExp(r"title: const Text\('U.O.O-U,Oc O U,O.O.*O.USO.!', style:"), "title: const Text('محاكمة المافيا!', style:");
  content = content.replaceAll(RegExp(r"Text\(\s*'.*'\,\s*style: const TextStyle\(color: AppTheme.textSecondary"), "Text('حصل على \${widget.votesCount} أصوات', style: const TextStyle(color: AppTheme.textSecondary");
  content = content.replaceAll(RegExp(r"const Text\('.* U\+U\?O3U.', style:"), "const Text('ثانية للدفاع عن نفسه', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('O.*O_O. O U,U.O U,O.', style:"), "child: const Text('ابدأ المؤقت', style:");
  content = content.replaceAll(RegExp(r"const Text\('O.*O1O_ O U\+O.U.O O. O U,O.O.*O.USO.OO O O3O.U, O U,O.U.USO1:', style:"), "const Text('بعد انتهاء وقت الدفاع:', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('O.O.USUSO. O U,O.O.U\^O O.', style:"), "child: const Text('تغيير التصويت', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('O.O.U.USO_ O U,O.U,O.O O.', style:"), "child: const Text('تأكيد الإعدام', style:");

  // AppBar
  content = content.replaceAll(RegExp(r"title: const Text\('O.O.O O. O U,U.O-U.U.O.', style:"), "title: const Text('قاعة المحكمة', style:");
  
  // Result Dialog
  content = content.replaceAll(RegExp(r"title: const Text\('U\+O.USO O. O U,O.O.U\^O O.!', style:"), "title: const Text('نتيجة التصويت!', style:");
  content = content.replaceAll(RegExp(r"const Text\('U,U. O.O. O.O.U\^USO. O.O_ O.O-O_', style:"), "const Text('لم يتم التصويت ضد أحد', style:");
  content = content.replaceAll(RegExp(r"Text\('O.O. O.O.U.O_ \$\{eliminated.name\}!', style:"), "Text('تم إعدام \${eliminated.name}!', style:");
  content = content.replaceAll(RegExp(r"Text\('.*: \$\{AppTheme.roleArabicName\(eliminated.role\)\}', style:"), "Text('كان: \${AppTheme.roleArabicName(eliminated.role)}', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('O.O.O O.O. O U,U,USU,Oc', style:"), "child: const Text('متابعة إلى الليلة', style:");

  // Main UI
  content = content.replaceAll(RegExp(r"const Text\('O.O.U\+ U\^U,O. O U,O.O.U\^O O.', style:"), "const Text('حان وقت التصويت', style:");
  content = content.replaceAll(RegExp(r"const Text\('O.O.O. O1U,U\% O.O3U. U.U, U,O.O.O. U,O.O.O.O.O. U.U\+ O3USO.U\^O. O.O.O.', style:"), "const Text('اضغط على اسم كل لاعب لاختيار من سيصوت ضده', style:");
  content = content.replaceAll(RegExp(r"child: const Text\('U\?O.O.O. O U,O.O.U\^O O.', style:"), "child: const Text('حساب الأصوات', style:");

  content = content.replaceAll(RegExp(r"Text\('.*U\^O O'"), "Text('صوت لـ'");

  file.writeAsStringSync(content);
}