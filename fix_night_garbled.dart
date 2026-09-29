import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  
  // Clean up all garbled strings safely
  content = content.replaceAll("O\"OU^O O1O U,US O OUUS:\\n\\nO U,UU, USOU.O  O1USU+USU\\nO U,U.O U?USO  OU?OO O1USU+USUO  \\n(U,U,OO1O OU? U?U,O)\\nO U,U.O U?USO  OOU.O \\nO U,UU, USU?OO", "الكل يغمض عينيه\nالمافيا يفتحون أعينهم\nالمافيا يغمضون\nالكل يفتح");
  content = content.replaceAll("O U,U,USU, 1 (OO1O OU?)", "الليلة الأولى (التعارف)");
  content = content.replaceAll("OOUUSO_ O U,OOOO O", "تأكيد الإجراء");
  content = content.replaceAll("O OrOO O U,UO_U?:", "اختر الهدف:");
  content = content.replaceAll("OU,U,U% O-U.O USOc O3O O\"U,Oc", "تلقى حماية سابقة");
  content = content.replaceAll("OUSO U.OO O-", "غير متاح");
  
  // Scaffold colors
  content = content.replaceAll("backgroundColor: AppTheme.background", "backgroundColor: const Color(0xFF07070B)");
  
  // ElevatedButtons styles -> Glassmorphic / Glowing
  content = content.replaceAll("backgroundColor: step.color,", "backgroundColor: step.color,\n                      elevation: 10,\n                      shadowColor: step.color.withValues(alpha: 0.5),");
  
  // AppBar styling
  content = content.replaceAll("appBar: AppBar(title: const Text('الليلة الأولى (التعارف)')),", "appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('الليلة الأولى (التعارف)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),");
  
  file.writeAsStringSync(content);
}