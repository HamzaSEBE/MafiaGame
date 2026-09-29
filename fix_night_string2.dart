import 'dart:io';
void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    "'O\"OU^O O1O U,US U,U,:\n\nO U,UU, USOU.O  O1USU+USU\nO U,U.O U?USO  OU?OO- O1USU+USUO  (U,U,OO1O OU? U?U,O)\nO U,U.O U?USO  OOU.O \nO U,UU, USU?OO-'",
    "'بصوت عالي قل:\\n\\nالكل يغمض عينيه\\nالمافيا تفتح عينيها (للتعارف فقط)\\nالمافيا تغمض\\nالكل يفتح'"
  );
  file.writeAsStringSync(content);
}