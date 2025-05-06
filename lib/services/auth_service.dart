import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email and password
  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } catch (e) {
      return 'Sign up failed: ${e.toString()}';
    }
  }

  // Sign in with email and password
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } catch (e) {
      return 'Sign in failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } catch (e) {
      return 'Sign out failed: ${e.toString()}';
    }
  }
}
