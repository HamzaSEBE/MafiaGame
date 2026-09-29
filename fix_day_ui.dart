import 'dart:io';

void main() {
  void fixScreen(String path) {
    final file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    
    // Convert background to glassmorphism gradient
    content = content.replaceAll("backgroundColor: AppTheme.background,", "backgroundColor: const Color(0xFF07070B),");
    final stackStart = "Stack(\n              children: [";
    final stackStartNew = "Stack(\n              children: [\n                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.5, colors: [Color(0xFF151826), Color(0xFF0A0C13), Color(0xFF07070B)])))),";
    
    content = content.replaceAll(stackStart, stackStartNew);
    
    // Fix garbled Arabic
    content = content.replaceAll("OU+UO O O U,U,O1O\"OcOY", "إنهاء اللعبة؟");
    content = content.replaceAll("UU, OU+O U.OOUO_ OU+U OOUSO_ OU+UO O UOU O U,U,O1O\"Oc U^O U,O1U^O_Oc \\nU,U,U,O OU.Oc O U,OOUSO3USOcOY", "هل أنت متأكد أنك تريد إنهاء اللعبة والعودة للرئيسية؟");
    content = content.replaceAll("OU,OO O", "إلغاء");
    
    file.writeAsStringSync(content);
  }
  
  fixScreen('lib/presentation/day/day_screen.dart');
  fixScreen('lib/presentation/day/voting_screen.dart');
}