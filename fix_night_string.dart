import 'dart:io';

void main() {
  final file = File('lib/presentation/night/night_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("بصوت عالي قل:\n\nالكل يغمض عينيه\nالمافيا تفتح عينيها (للتعارف فقط)\nالمافيا تغمض\nالكل يفتح", "بصوت عالي قل:\\n\\nالكل يغمض عينيه\\nالمافيا تفتح عينيها (للتعارف فقط)\\nالمافيا تغمض\\nالكل يفتح");
  content = content.replaceAll("\nالكل يغمض", "\\nالكل يغمض");
  content = content.replaceAll("\nالمافيا تفتح", "\\nالمافيا تفتح");
  content = content.replaceAll("\nالمافيا تغمض", "\\nالمافيا تغمض");
  content = content.replaceAll("\nالكل يفتح", "\\nالكل يفتح");
  
  // Just in case, let's fix the string completely
  content = content.replaceAll("'" + "بصوت عالي قل:\\n\\nالكل يغمض عينيه\\nالمافيا تفتح عينيها (للتعارف فقط)\\nالمافيا تغمض\\nالكل يفتح" + "'", "'بصوت عالي قل:\\n\\nالكل يغمض عينيه\\nالمافيا تفتح عينيها (للتعارف فقط)\\nالمافيا تغمض\\nالكل يفتح'");
  file.writeAsStringSync(content);
}