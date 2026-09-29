import 'dart:io';

void main() {
  final file = File('lib/presentation/profile/profile_screen.dart');
  var content = file.readAsStringSync();
  
  // Need to ensure authServiceProvider is available. It might be already since it's a ConsumerState.
  if (!content.contains('auth_service.dart')) {
    content = "import 'package:mafia_nightfall/data/services/auth_service.dart';\n" + content;
  }
  
  content = content.replaceAll(
    "await _auth.signOut();", 
    "await ref.read(authServiceProvider).signOut();"
  );
  
  file.writeAsStringSync(content);
  print('Fixed Profile Logout!');
}