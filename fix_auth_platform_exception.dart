import 'dart:io';

void main() {
  final file = File('lib/data/services/auth_service.dart');
  var content = file.readAsStringSync();
  
  final oldSignOut = """
  Future<void> signOut() async {
    // Force complete sign out by re-instantiating if needed
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }
      await googleSignIn.signOut();
    } catch (e) {
      print('Google SignOut Error: \$e');
    }
    
    // Fallback using class instance
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
    } catch (_) {}
    
    await _auth.signOut();
  }
""";

  final newSignOut = """
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
    } catch (_) {}
    
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    
    await _auth.signOut();
  }
""";

  if (content.contains('// Force complete sign out by re-instantiating if needed')) {
    content = content.replaceFirst(oldSignOut, newSignOut);
  } else {
    // Fallback if the string doesn't match exactly
    final startIndex = content.indexOf('Future<void> signOut() async {');
    final endIndex = content.indexOf('Future<void> resetPassword', startIndex);
    content = content.replaceRange(startIndex, endIndex, newSignOut + '\n\n  ');
  }

  file.writeAsStringSync(content);
  print('Fixed AuthService SignOut!');
}