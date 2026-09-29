import 'dart:io';

void main() {
  final file = File('lib/presentation/voting/voting_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("U.U+ USOrOO O", "لمن سيصوت");
  content = content.replaceAll("O OOU^USO", "تصويت");
  content = content.replaceAll("O1U+ U,U. USOOU^O", "لم يصوت");
  content = content.replaceAll("OO1U,U% O U,O OU^USO", "إنهاء التصويت");
  content = content.replaceAll("OU,OO O", "إلغاء");
  content = content.replaceAll("OOUUSO_ O U,OOO", "تأكيد الإعدام");
  content = content.replaceAll("OO-O O O U,O OU,", "أعدم");
  content = content.replaceAll("OU+UO O O U,U,O1O\"OcOY", "إنهاء اللعبة؟");
  content = content.replaceAll("UU, OU+O U.OOUO_ OU+U OOUSO_ OU+UO O UOU O U,U,O1O\"Oc U^O U,O1U^O_Oc \\nU,U,U,O OU.Oc O U,OOUSO3USOcOY", "هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟");
  
  // Scaffold styles
  content = content.replaceAll("backgroundColor: AppTheme.background", "backgroundColor: const Color(0xFF07070B)");
  final stackStart = "Stack(\n        children: [";
  final stackStartNew = "Stack(\n        children: [\n          Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.5, colors: [Color(0xFF151826), Color(0xFF0A0C13), Color(0xFF07070B)])))),";
  content = content.replaceAll(stackStart, stackStartNew);
  
  file.writeAsStringSync(content);
}