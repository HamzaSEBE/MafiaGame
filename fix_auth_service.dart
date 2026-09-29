import 'dart:io';

void main() {
  final file = File('lib/data/services/auth_service.dart');
  var content = file.readAsStringSync();
  
  final oldSignOut = """
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
""";

  final newSignOut = """
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
""";

  content = content.replaceFirst(oldSignOut, newSignOut);
  
  // Also fix account linking error handling in signInWithGoogle
  final oldSignInGoogle = """
    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
""";

  final newSignInGoogle = """
    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential userCredential;
    try {
      userCredential = await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('هذا البريد الإلكتروني مسجل مسبقاً بطريقة مختلفة (عبر الإيميل وكلمة المرور). قم بتسجيل الدخول بهما ثم اربط حساب جوجل من الداخل.');
      }
      rethrow;
    }
""";

  content = content.replaceFirst(oldSignInGoogle, newSignInGoogle);

  file.writeAsStringSync(content);
  print('Fixed AuthService!');
}