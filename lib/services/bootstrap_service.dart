import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/auth_constants.dart';
import '../core/constants/enums.dart';
import '../core/firebase/firestore_paths.dart';
import '../core/firebase/firestore_mappers.dart';
import '../models/app_user.dart';

/// Ensures the default admin account exists in Firebase (first launch / empty project).
class BootstrapService {
  Future<void> ensureDefaultAdmin() async {
    const email = AuthConstants.defaultAdminEmail;
    const password = AuthConstants.defaultAdminPassword;

    try {
      await _runBootstrap(email, password).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Bootstrap timed out — continuing to login screen.');
        },
      );
    } catch (e) {
      debugPrint('Bootstrap failed: $e');
    } finally {
      await _signOutIfNeeded();
    }
  }

  Future<void> _runBootstrap(String email, String password) async {
    final auth = FirebaseAuth.instance;

    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureAdminProfile(cred.user!.uid, email);
      debugPrint('Default admin verified.');
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found' &&
          e.code != 'invalid-credential' &&
          e.code != 'invalid-login-credentials') {
        debugPrint('Bootstrap admin sign-in: ${e.code}');
        return;
      }
    }

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureAdminProfile(cred.user!.uid, email);
      debugPrint('Default admin account created.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint(
          'Admin email exists but password may differ — reset in Firebase Console.',
        );
      } else {
        debugPrint('Bootstrap admin create failed: ${e.message}');
      }
    }
  }

  Future<void> _ensureAdminProfile(String uid, String email) async {
    try {
      final ref = StoreRefs(FirebaseFirestore.instance).user(uid);
      final snap = await ref.get();
      if (snap.exists && snap.data()?['role'] == UserRole.admin.name) {
        return;
      }
      await ref.set(
        AppUser(
          id: uid,
          name: AuthConstants.defaultAdminName,
          email: email,
          role: UserRole.admin,
        ).toMap(),
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      debugPrint('Bootstrap profile write failed: ${e.code} ${e.message}');
    }
  }

  Future<void> _signOutIfNeeded() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint('Bootstrap sign-out: $e');
    }
  }
}
