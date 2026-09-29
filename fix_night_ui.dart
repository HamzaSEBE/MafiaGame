import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  // Just replacing the scaffold background and garbled text with proper glassmorphism UI
  // Since it's a huge file, I will do some targeted replacements
  
  content = content.replaceAll("backgroundColor: AppTheme.background,", "backgroundColor: const Color(0xFF07070B),");
  
  // Add gradient background behind AnimatedBackground
  final stackStart = "Stack(\n              children: [";
  final stackStartNew = "Stack(\n              children: [\n                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.5, colors: [Color(0xFF130E0A), Color(0xFF07070B)])))),";
  
  content = content.replaceAll(stackStart, stackStartNew);
  
  // Convert basic Scaffold to use the gradient as well
  content = content.replaceAll("return Scaffold(", "return Scaffold(backgroundColor: const Color(0xFF07070B),");
  
  // Fix garbled Arabic text in Night 1
  final garbledNight1 = "O U,U,USU, 1 (OO1O OU?)";
  content = content.replaceAll(garbledNight1, "الليلة الأولى (التعارف)");
  
  content = content.replaceAll("OO U? U,O O1O\"USU+ OU^U,O U<", "أضف لاعبين أولاً");
  content = content.replaceAll("O\"OU^O O1O U,US O OUUS:\\n\\nO U,UU, USOU.O  O1USU+USU\\nO U,U.O U?USO  OU?OO O1USU+USUO  \\n(U,U,OO1O OU? U?U,O)\\nO U,U.O U?USO  OOU.O \\nO U,UU, USU?OO", 
  "الكل يغمض عينيه\nالمافيا يفتحون أعينهم\n(للتعارف فقط)\nالمافيا يغمضون\nالكل يفتح");
  
  content = content.replaceAll("OOOO O U,U,USU,Oc", "بدء الليلة");
  content = content.replaceAll("OU+UO O O U,U,O1O\"OcOY", "إنهاء اللعبة؟");
  content = content.replaceAll("UU, OU+O U.OOUO_ OU+U OOUSO_ OU+UO O UOU O U,U,O1O\"Oc U^O U,O1U^O_Oc \\nU,U,U,O OU.Oc O U,OOUSO3USOcOY", "هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟");
  content = content.replaceAll("OU,OO O", "إلغاء");
  content = content.replaceAll("OO1U,U%", "استمرار");
  content = content.replaceAll("O1U,UUS", "إنهاء");
  content = content.replaceAll("OU+O O U,U,USU,Oc!", "انتهت الليلة!");
  content = content.replaceAll("OU+O O U,U,USU,Oc", "إنهاء الليلة");
  content = content.replaceAll("U,U, O U+O O1", "متابعة");
  
  file.writeAsStringSync(content);
}