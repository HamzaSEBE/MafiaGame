import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({required String email, required String password, required String displayName, required String username}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(displayName);
    await credential.user?.sendEmailVerification();
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'displayName': displayName,
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential;
    try {
      userCredential = await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('هذا البريد الإلكتروني مسجل مسبقاً بطريقة مختلفة. قم بتسجيل الدخول بكلمة المرور.');
      }
      rethrow;
    }
    
    final user = userCredential.user;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        String baseUsername = user.email?.split('@').first ?? user.uid.substring(0, 8);
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': user.displayName ?? 'لاعب جوجل',
          'username': baseUsername,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    return userCredential;
  }

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

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}