import 'dart:io';

void fixFile(String path, Map<String, String> replacements) {
  var file = File(path);
  if (!file.existsSync()) return;
  
  // Use ISO-8859-1 to read raw bytes without throwing UTF-8 errors on Windows
  var bytes = file.readAsBytesSync();
  var content = String.fromCharCodes(bytes);
  
  for (var entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }
  
  // Ensure we output true UTF-8
  file.writeAsStringSync(content);
}

void main() {
  fixFile('lib/presentation/setup/setup_screen.dart', {
    'O U,U,O O1O"U^U+ O U,U.O-U?U^O,U^U+:': 'اللاعبون المحفوظون:',
    'O U,OO_U^O O O U,U.U^OO1Oc:': 'الأدوار الموزعة:',
    'U?OUSU, O U,U.O U?USO ': 'فريق المافيا',
    'U?OUSU, O U,U.U^O OU+USU+': 'فريق المواطنين',
    'OO-O_U^O O3U. O U,U,O O1O"': 'أدخل اسم اللاعب',
    'OOO O O U,U,O O1O"U^U+': 'إعداد اللاعبين',
    'OOO O O U,OO_U^O O': 'إعداد الأدوار',
    'O"O_O_ O U,U,O OO': 'بدء اللعبة',
    'O U,OO1O_O O_O O': 'الإعدادات',
  });

  fixFile('lib/presentation/reveal/role_reveal_screen.dart', {
    'O O3OU,U. O U,UO OU? O U,U,O O1O"': 'استلم الهاتف اللاعب',
    'O O3O-O" U,O O3OU,O U. O U,UO OU?': 'اسحب لاستلام الهاتف',
    'OO-OUSO: U,O  OO-O U^U, UO\'U? O U,O_U^O U,O"U, OO3U,USU. O U,UO OU?!': 'تحذير: لا تحاول كشف الدور قبل تسليم الهاتف!',
    'O O OO O"O O3OU.OO O U,OO USOc O"OO U,OU': 'اضغط باستمرار لرؤية بطاقتك',
    'O"U.OOO_ OU?O1 OOO"O1UOO O3USOU. U,U?U, O U,O\'O O\'Oc.': 'بمجرد رفع إصبعك، سيتم قفل الشاشة.',
    'U.O-O U^U,Oc OO\'!': 'محاولة غش!',
    'O U,U,O O1O" O U,O3O O"U, USO-O U^U, UO\'U? O_U^O': 'اللاعب السابق يحاول كشف دور',
  });

  fixFile('lib/presentation/settings/settings_screen.dart', {
    'OU. OU?O, O U,OO1O_O O_O O O"U+OO O': 'تم حفظ الإعدادات بنجاح',
    'OO1O_O O_O O O U,OO3U.O O': 'إعدادات الأسماء',
    'OU?O, O U,OO1O_O O_O O': 'حفظ الإعدادات',
    'OO-O_U^O OO3U.O O U,OOO_USOc O U,U.OUSO U,O O3UO O U.O-U?U^O,Oc': 'أدخل أسماء لاعبين ليتم حفظها كمسودة',
  });

  fixFile('lib/presentation/profile/profile_screen.dart', {
    'U?O\'U, OOO_USO O U,OU^OOc': 'فشل تحديث الصورة',
    'OO1O_USU, O U,O O3U.': 'تعديل الاسم',
    'OU,OO O': 'إلغاء',
    'OU?O,': 'حفظ',
    'O U,U.U,U? O U,O\'OrOUS': 'الملف الشخصي',
    'OO3U. O U,U.O3OOO-O_U.': 'اسم المستخدم',
    'O U,O"O1USO_': 'البريد',
    'O O OU O U,O-O3O O"': 'تسجيل خروج',
    'OO O1O O OOO U.O': 'تعديل معلوماتك',
  });

  fixFile('lib/presentation/stats/stats_screen.dart', {
    'OrOO U?US OOU.USU, O U,O"USO U+O O': 'خطأ في تحميل البيانات',
    'U,O  OU^OO_ OOOO OUSO O O"O1O_': 'لا توجد إحصائيات بعد',
    'O U,OOOO OUSO O': 'الإحصائيات',
    'O U,U.OOUSO O O U,U.U,O O^O"O': 'المباريات الملعوبة',
    'O U,O\'U+OOO OO O': 'الانتصارات',
    'U.O O_U, O U,O\'U+OOO O': 'معدل الانتصار',
    'UO O O U,U.O U?USO ': 'فوز كالمافيا',
    'UO O O U,U.U^O OU+U^U+': 'فوز كالمواطنين',
  });
}
