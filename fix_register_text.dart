import 'dart:io';

void main() {
  final file = File('lib/presentation/auth/register_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("labelText: 'اسم المستخدم (English)',", "labelText: 'اسم المستخدم بالإنجليزية',");
  file.writeAsStringSync(content);
}