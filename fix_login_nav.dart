import 'dart:io';

void main() {
  final file = File('lib/presentation/auth/login_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('auth_wrapper.dart')) {
    content = "import 'package:mafia_nightfall/presentation/auth/auth_wrapper.dart';\n" + content;
  }
  
  // In _login()
  content = content.replaceAll(
    "await ref.read(authServiceProvider).signIn(\n              email: emailToUse,\n              password: password,\n            );",
    "await ref.read(authServiceProvider).signIn(\n              email: emailToUse,\n              password: password,\n            );\n        if (mounted) {\n          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthWrapper()), (r) => false);\n        }"
  );

  // In _loginWithGoogle()
  content = content.replaceAll(
    "final result = await ref.read(authServiceProvider).signInWithGoogle();\n      if (result == null && mounted) {",
    "final result = await ref.read(authServiceProvider).signInWithGoogle();\n      if (result != null && mounted) {\n        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthWrapper()), (r) => false);\n      } else if (result == null && mounted) {"
  );

  file.writeAsStringSync(content);
  print('Fixed LoginScreen navigation!');
}