import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Creates cashier Auth accounts without signing out the current admin.
class FirebaseAuthService {
  Future<UserCredential> signIn(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  User? get currentFirebaseUser => FirebaseAuth.instance.currentUser;

  Stream<User?> authStateChanges() => FirebaseAuth.instance.authStateChanges();

  Future<UserCredential> createCashierAuthAccount({
    required String email,
    required String password,
  }) async {
    final defaultApp = Firebase.app();
    final secondary = await Firebase.initializeApp(
      name: 'RetailXSecondary',
      options: defaultApp.options,
    );
    try {
      return await FirebaseAuth.instanceFor(app: secondary)
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } finally {
      await secondary.delete();
    }
  }

  Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }
}
