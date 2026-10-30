// PLACEHOLDER ONLY.
// Run `flutterfire configure` from the project root to replace this file with
// your project's real Firebase options. Do not publish real configuration
// values in a public repository if your project policy prohibits it.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for Fuchsia.');
    }
  }

  // These placeholder values are not valid. Replace this file using:
  // flutterfire configure

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCs3mhrzy2lrN3oxDInSbvyHWJCztgI-YU',
    appId: '1:743981396524:web:100a2b441103bb9ad85789',
    messagingSenderId: '743981396524',
    projectId: 'safewalk-student-safety',
    authDomain: 'safewalk-student-safety.firebaseapp.com',
    storageBucket: 'safewalk-student-safety.firebasestorage.app',
    measurementId: 'G-5NK4YC39ED',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKyFT_27ooszybT5RNYlgY1W6PI6pLuUY',
    appId: '1:743981396524:android:04cd83dfe8bf4568d85789',
    messagingSenderId: '743981396524',
    projectId: 'safewalk-student-safety',
    storageBucket: 'safewalk-student-safety.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAvaqoGTVnpz14LQhE-4ECOG4hNJDYYHiA',
    appId: '1:743981396524:ios:4f36c2d51b35e0c9d85789',
    messagingSenderId: '743981396524',
    projectId: 'safewalk-student-safety',
    storageBucket: 'safewalk-student-safety.firebasestorage.app',
    iosBundleId: 'com.example.safewalk',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAvaqoGTVnpz14LQhE-4ECOG4hNJDYYHiA',
    appId: '1:743981396524:ios:4f36c2d51b35e0c9d85789',
    messagingSenderId: '743981396524',
    projectId: 'safewalk-student-safety',
    storageBucket: 'safewalk-student-safety.firebasestorage.app',
    iosBundleId: 'com.example.safewalk',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCs3mhrzy2lrN3oxDInSbvyHWJCztgI-YU',
    appId: '1:743981396524:web:4e52a247c073320fd85789',
    messagingSenderId: '743981396524',
    projectId: 'safewalk-student-safety',
    authDomain: 'safewalk-student-safety.firebaseapp.com',
    storageBucket: 'safewalk-student-safety.firebasestorage.app',
    measurementId: 'G-19DMLSG1V7',
  );
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FIREBASE_LINUX_API_KEY',
    appId: 'REPLACE_WITH_FIREBASE_LINUX_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.firebasestorage.app',
  );
}
