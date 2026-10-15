import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/firebase/firestore_mappers.dart';
import '../core/firebase/firestore_paths.dart';
import '../models/app_user.dart';
import '../services/firebase_auth_service.dart';
import '../services/pos_store.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._store, this._authService) {
    _authSub = _authService.authStateChanges().listen(_onAuthChanged);
  }

  final PosStore _store;
  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authSub;

  AppUser? _currentUser;
  bool _ready = false;
  bool _splashComplete = false;
  UserRole? _loginRole;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get role => _currentUser?.role;
  bool get authReady => _ready;
  bool get splashComplete => _splashComplete;
  UserRole? get loginRole => _loginRole;

  /// Called after splash animation + bootstrap so auth is not racing bootstrap sign-in.
  Future<void> finishSplash() async {
    _splashComplete = true;
    notifyListeners();
    await _applyAuthUser(_authService.currentFirebaseUser);
  }

  void selectLoginRole(UserRole role) {
    _loginRole = role;
    notifyListeners();
  }

  void clearLoginRole() {
    _loginRole = null;
    notifyListeners();
  }

  Future<void> _onAuthChanged(User? user) async {
    if (!_splashComplete) {
      return;
    }
    await _applyAuthUser(user);
  }

  Future<void> _applyAuthUser(User? user) async {
    if (user == null) {
      _currentUser = null;
      _store.detach();
      _ready = true;
      notifyListeners();
      return;
    }

    _ready = false;
    notifyListeners();

    try {
      final doc =
          await StoreRefs(FirebaseFirestore.instance).user(user.uid).get();

      if (!doc.exists) {
        await _authService.signOut();
        _currentUser = null;
        _store.detach();
        _ready = true;
        notifyListeners();
        return;
      }

      final profile = AppUserMap.fromDoc(user.uid, doc.data()!);
      if (!profile.active) {
        await _authService.signOut();
        _currentUser = null;
        _store.detach();
        _ready = true;
        notifyListeners();
        return;
      }

      _currentUser = profile;
      await _store.attach();
    } catch (e) {
      debugPrint('Auth profile load failed: $e');
      await _authService.signOut();
      _currentUser = null;
      _store.detach();
    }
    _ready = true;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    final expected = _loginRole;
    if (expected == null) {
      return 'Please select Admin or Cashier first';
    }

    try {
      final cred = await _authService.signIn(email, password);
      final uid = cred.user!.uid;
      final doc = await StoreRefs(FirebaseFirestore.instance).user(uid).get();

      if (!doc.exists) {
        await _authService.signOut();
        return 'User profile not found. Contact admin.';
      }

      final profile = AppUserMap.fromDoc(uid, doc.data()!);
      if (!profile.active) {
        await _authService.signOut();
        return 'This account has been deactivated';
      }

      if (profile.role != expected) {
        await _authService.signOut();
        return expected == UserRole.admin
            ? 'This account is not an admin. Choose Cashier to sign in.'
            : 'This account is not a cashier. Choose Admin to sign in.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Firestore blocked this login. In Firebase Console → Firestore → '
            'Rules, publish the latest firestore.rules from this project '
            '(users must be allowed to read/create their own profile).';
      }
      return e.message ?? 'Could not load user profile';
    } catch (e) {
      debugPrint('Login failed: $e');
      return 'Sign in failed';
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return e.message ?? 'Sign in failed (${e.code})';
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    clearLoginRole();
  }

  Future<String?> createCashier({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _authService.createCashierAuthAccount(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      await StoreRefs(FirebaseFirestore.instance).user(uid).set(
            AppUser(
              id: uid,
              name: name.trim(),
              email: email.trim(),
              role: UserRole.cashier,
            ).toMap(),
          );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not create cashier';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateUserProfile(AppUser user) async {
    try {
      await StoreRefs(FirebaseFirestore.instance).user(user.id).update({
        'name': user.name,
        'email': user.email,
      });
      if (_currentUser?.id == user.id) {
        _currentUser = user;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return 'Could not update user';
    }
  }

  Future<String?> deactivateCashier(String uid) async {
    try {
      await StoreRefs(FirebaseFirestore.instance).user(uid).update({
        'active': false,
      });
      return null;
    } catch (e) {
      return 'Could not deactivate cashier';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not send reset email';
    }
  }

  bool canAccess(NavSection section) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == UserRole.admin) {
      return switch (section) {
        NavSection.pos || NavSection.suppliers => false,
        NavSection.dashboard ||
        NavSection.products ||
        NavSection.inventory ||
        NavSection.sales ||
        NavSection.customers ||
        NavSection.cashiers ||
        NavSection.reports ||
        NavSection.settings =>
          true,
      };
    }
    return switch (section) {
      NavSection.dashboard ||
      NavSection.pos ||
      NavSection.products ||
      NavSection.inventory ||
      NavSection.sales ||
      NavSection.customers =>
        true,
      NavSection.cashiers ||
      NavSection.suppliers ||
      NavSection.reports ||
      NavSection.settings =>
        false,
    };
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

enum NavSection {
  dashboard,
  products,
  pos,
  inventory,
  sales,
  customers,
  cashiers,
  suppliers,
  reports,
  settings,
}
