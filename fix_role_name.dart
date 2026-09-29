import 'dart:io';

void main() {
  final file = File('lib/presentation/theme/app_theme.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("case Role.citizensBoy:    return 'المواطن الشجاع';", "case Role.citizensBoy:    return 'ولد المواطنين';");
  file.writeAsStringSync(content);
  print('Role name updated to ولد المواطنين');
}