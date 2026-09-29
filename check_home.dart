import 'dart:io';

void main() {
  final file = File('lib/presentation/home/home_screen.dart');
  var content = file.readAsStringSync();
  print("Contains لاعب: ${content.contains('لاعب')}");
  print("Contains Ù„Ø§Ø¹Ø¨ (Mojibake): ${content.contains('Ù„Ø§Ø¹Ø¨')}");
}