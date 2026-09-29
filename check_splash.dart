import 'dart:io';

void main() {
  final file = File('lib/presentation/splash/splash_screen.dart');
  var content = file.readAsStringSync();
  print("Contains مافيا: ${content.contains('مافيا')}");
  print("Contains Ù…Ø§Ù ÙŠØ§ (Mojibake): ${content.contains('Ù…Ø§Ù ÙŠØ§')}");
}