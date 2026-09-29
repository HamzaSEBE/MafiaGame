import 'dart:io';

void main() {
  final file = File('lib/presentation/profile/profile_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('auth_wrapper.dart')) {
    content = "import 'package:mafia_nightfall/presentation/auth/auth_wrapper.dart';\n" + content;
  }
  
  content = content.replaceAll(
    "MaterialPageRoute(builder: (_) => const LoginScreen()),",
    "MaterialPageRoute(builder: (_) => const AuthWrapper()),"
  );

  file.writeAsStringSync(content);
  print('Fixed ProfileScreen navigation!');
}