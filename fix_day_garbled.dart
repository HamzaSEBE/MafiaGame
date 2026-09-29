import 'dart:io';

void main() {
  final file = File('lib/presentation/day/day_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("O U,U+UO O \$round", "النهار \$round");
  content = content.replaceAll("OU+UO O O U,U,O1O\"Oc", "إنهاء اللعبة");
  content = content.replaceAll("OOUO O O U,OU,O OU O O U,UUSUO  5 O OU OO-! U,OU,O OU^O O OU%O", "تحدثوا وتشاوروا لمدة 5 دقائق! من هو القاتل؟");
  content = content.replaceAll("O U,OOUSO O U,OOO O O U,O O U,OO OO. (O U,U+O O)", "الأحياء (النقاش)");
  content = content.replaceAll("OOU OU3UO O U.U, O OU, O U,OU+O O U,U.O U?USO", "تم إسكاته من قبل بنت المافيا");
  content = content.replaceAll("O U,OU.U^O O", "الأموات");
  content = content.replaceAll("O U,U+O OU, O U,U,O US O U,OO U^USO", "الانتقال إلى التصويت");
  
  file.writeAsStringSync(content);
}