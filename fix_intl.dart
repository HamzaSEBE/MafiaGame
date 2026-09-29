import 'dart:io';

void main() {
  final file = File('lib/presentation/widgets/newspaper_widget.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll("import 'package:intl/intl.dart';", "");
  file.writeAsStringSync(content);
}