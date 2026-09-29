import 'dart:io';

void main() {
  final file = File('lib/data/services/auth_service.dart');
  var content = file.readAsStringSync();
  
  final regex = RegExp(r"throw Exception\('.*'\);");
  content = content.replaceFirst(
    regex, 
    "throw Exception('هذا البريد الإلكتروني مسجل مسبقاً عبر كلمة المرور. قم بتسجيل الدخول بكلمة المرور لربط الحساب.');"
  );
  
  file.writeAsStringSync(content);
  print('Fixed Arabic encoding in auth_service!');
}