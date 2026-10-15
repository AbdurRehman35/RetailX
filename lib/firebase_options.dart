// Firebase options for project poss-c8826 (Web configured from Firebase Console).
// For Android/iOS/macOS, run `flutterfire configure` and add those apps in Firebase.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Add a Windows app in Firebase Console, then run flutterfire configure.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Add a Linux app in Firebase Console, then run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyADsMJ4CUYYuc8Iz0K3dvqeDNvWXn6ZSsY',
    appId: '1:398100033628:web:eb1e467f820e8b80ff3699',
    messagingSenderId: '398100033628',
    projectId: 'poss-c8826',
    authDomain: 'poss-c8826.firebaseapp.com',
    storageBucket: 'poss-c8826.firebasestorage.app',
    measurementId: 'G-0NM8178XSS',
  );

  /// Register Android in Firebase Console, then run `flutterfire configure`.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADsMJ4CUYYuc8Iz0K3dvqeDNvWXn6ZSsY',
    appId: '1:398100033628:web:eb1e467f820e8b80ff3699',
    messagingSenderId: '398100033628',
    projectId: 'poss-c8826',
    storageBucket: 'poss-c8826.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyADsMJ4CUYYuc8Iz0K3dvqeDNvWXn6ZSsY',
    appId: '1:398100033628:web:eb1e467f820e8b80ff3699',
    messagingSenderId: '398100033628',
    projectId: 'poss-c8826',
    storageBucket: 'poss-c8826.firebasestorage.app',
    iosBundleId: 'com.example.retailx',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyADsMJ4CUYYuc8Iz0K3dvqeDNvWXn6ZSsY',
    appId: '1:398100033628:web:eb1e467f820e8b80ff3699',
    messagingSenderId: '398100033628',
    projectId: 'poss-c8826',
    storageBucket: 'poss-c8826.firebasestorage.app',
    iosBundleId: 'com.example.retailx',
  );
}
