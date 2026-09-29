import 'dart:io';

void main() {
  final file = File('lib/data/services/auth_service.dart');
  var content = file.readAsStringSync();
  
  // Find where FirebaseAuthException is caught
  int startIndex = content.indexOf('on FirebaseAuthException');
  int endIndex = content.indexOf('rethrow;', startIndex) + 'rethrow;'.length + 5;
  
  String correctBlock = """on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('هذا البريد الإلكتروني مسجل مسبقاً بطريقة مختلفة. قم بتسجيل الدخول بكلمة المرور.');
      }
      rethrow;
    }""";
    
  content = content.replaceRange(startIndex, endIndex, correctBlock);
  file.writeAsStringSync(content);
  print('Fixed correctly.');
}