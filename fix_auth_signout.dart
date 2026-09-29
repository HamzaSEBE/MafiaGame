import 'dart:io';

void main() {
  final file = File('lib/data/services/auth_service.dart');
  var content = file.readAsStringSync();
  
  final oldSignOut = """
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

  final newSignOut = """
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
  
  content = content.replaceFirst(oldSignOut, newSignOut);
  file.writeAsStringSync(content);
}