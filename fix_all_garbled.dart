import 'dart:io';

void main() {
  void fixFile(String path, Map<String, String> replacements) {
    final file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    
    // Add Glassmorphism background if missing
    if (content.contains('const AnimatedBackground(),')) {
      content = content.replaceAll(
        'const AnimatedBackground(),', 
        'Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.5, colors: [Color(0xFF261D15), Color(0xFF130E0A), Color(0xFF07070B)])))),\n          const AnimatedBackground(),'
      );
    }
    
    content = content.replaceAll('backgroundColor: AppTheme.background', 'backgroundColor: const Color(0xFF07070B)');
    
    for (var entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    file.writeAsStringSync(content);
  }

  // Night Screen Replacements
  fixFile('lib/presentation/night/night_screen.dart', {
    "O U,U,USU, 1 (OO1O OU?)": "الليلة الأولى (التعارف)",
    "O\"OU^O O1O U,US O OUUS:\\n\\nO U,UU, USOU.O  O1USU+USU\\nO U,U.O U?USO  OU?OO O1USU+USUO  \\n(U,U,OO1O OU? U?U,O)\\nO U,U.O U?USO  OOU.O \\nO U,UU, USU?OO": "بصوت عالي احكي:\n\nالكل يغمض عينيه\nالمافيا يفتحون أعينهم\nالمافيا يغمضون\nالكل يفتح",
    "OUSO U.OO O-": "غير متاح",
    "OU,U,U% O-U.O USOc O3O O\"U,Oc": "تلقى حماية سابقة",
    "O OrOO O U,UO_U?:": "اختر الهدف:",
    "OOUUSO_ O U,OOOO O": "تأكيد الإجراء",
    "OU,OO O": "إلغاء",
    "OU+UO O O U,U,O1O\"OcOY": "إنهاء اللعبة؟",
    "UU, OU+O U.OOUO_ OU+U OOUSO_ OU+UO O UOU O U,U,O1O\"Oc U^O U,O1U^O_Oc \\nU,U,U,O OU.Oc O U,OOUSO3USOcOY": "هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟",
    "U+O1U.OO OU+UO O": "تأكيد الإنهاء",
    "U,U, O U+O O1": "تخطي الليل",
  });

  // Day Screen Replacements
  fixFile('lib/presentation/day/day_screen.dart', {
    "O U,U+UO O": "النهار",
    "OU+UO O O U,U,O1O\"Oc": "إنهاء اللعبة",
    "OOO_ O O O U,OOO O U,OO O O O. (O U,U+O O)": "الأحياء (النقاش)",
    "OO OU3UO O U.U, O OU, O U,U.O U?USO": "مُسكت بواسطة المافيا",
    "O U,OU.U^O O": "الأموات",
    "O U,U+O OU, O U,U,O US O U,OO U^USO": "الانتقال للتصويت",
    "OOO O O U,OO U,O O U O O U,UUSUO  5 O OU OO-! U,OU,O O U^O O OU%O": "تشاوروا وتناقشوا لمدة 5 دقائق! من هو القاتل؟"
  });

  // Voting Screen Replacements
  fixFile('lib/presentation/voting/voting_screen.dart', {
    "U.U+ USOrOO O": "لمن سيصوت",
    "OOU^USO": "تصويت",
    "O1U+ U,U. USOOU^O": "لم يصوت",
    "OO1U,U% O U,OO U^USO": "إنهاء التصويت",
    "OU,OO O": "إلغاء",
    "OOUUSO_ O U,OOOO O": "تأكيد الإجراء",
    "OO-O O O U,OO U,O": "أعدم",
    "OU+UO O O U,U,O1O\"OcOY": "إنهاء اللعبة؟",
    "UU, OU+O U.OOUO_ OU+U OOUSO_ OU+UO O UOU O U,U,O1O\"Oc U^O U,O1U^O_Oc U,U,U,O OU.Oc O U,OOUSO3USOcOY": "هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟",
    "U+O1U.OO OU+UO O": "تأكيد الإنهاء",
    "U?OO O U,OOU^O O": "تخطي التصويت",
    "U.OO-U,Oc O U,OO\"OUSO!": "وقت الدفاع!",
    "O-OU, O1U,U% OO1U,U% O U,OOU^O O": "حصل على عدد أصوات",
    "OO U+USOc U.OO\"U,USOc U,U,O_U?O O1 O1U+ U+U?O3U": "ثانية للدفاع عن نفسه",
    "O\"O_O O U,U.O U,O": "ابدأ المؤقت",
    "O\"O1O_ O U+OUO O O U,OO\"OUSOOO O O3OU, O U,OU.USO1:": "بعد انتهاء وقت الدفاع:",
    "OOUSUSO O U,OOU^O O": "تغيير التصويت",
    "OOUUSO_ O U,OU,OO O": "تأكيد الإعدام",
  });
  
  // Night Summary Screen Replacements
  fixFile('lib/presentation/night/night_summary_screen.dart', {
    "U.U,OrO O U,U,USU, (U,U,O-UU. U?U,O)": "ملخص الليلة (للحكم فقط)",
    "O U+OUU% O U,U,USU,OO U^OU,USU U.O  O-O_O U?US O U,O1OU.Oc:": "انتهت الليلة، وإليك ما حدث:",
    "O\"U+O O U,U.U^O OU+USU+ O-U.O O U,UO_U? O\"U+OO O-! U,U. USU?U,OU, OO-O_.": "تمت حماية الهدف بنجاح! لم يُقتل أحد.",
    "O O-USOc O U,U,USU, (OU. O OOUSO U,U):": "ضحية الليلة (تم اغتياله):",
    "OU. OO3UO OUU. (U,O  USO-U, U,UU. O U,UU,O U.):": "تم إسكاتهم (لا يحق لهم التحدث):",
    "OO_ U?O1U, O U,U.U^O OU+ O U,O'OO O1!": "رد فعل المواطن الشجاع!",
    "O\"O_O O U,U+UO O": "بدء النهار",
    "OO1O_ O U,U.O U,O": "متابعة",
    "OOUUSO_ O U,OU,OO O": "تأكيد الإعدام"
  });
}