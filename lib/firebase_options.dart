// Generated from google-services.json + GoogleService-Info.plist (project: testermandi)
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDuKfcJHhoT44B-HwV1MFiu3-_G6tFYrls',
    appId: '1:1098028238157:android:1d5a33dc5e257055c2e304',
    messagingSenderId: '1098028238157',
    projectId: 'testermandi',
    storageBucket: 'testermandi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAglvl__dM6xE9Z3KfSlu-BVtAIixzCrgw',
    appId: '1:1098028238157:ios:cabb325714f2a11cc2e304',
    messagingSenderId: '1098028238157',
    projectId: 'testermandi',
    storageBucket: 'testermandi.firebasestorage.app',
    iosBundleId: 'com.appvora.testermandi',
    iosClientId: '1098028238157-u5jq2an6dshlke87jrh3s09juijueioh.apps.googleusercontent.com',
  );
}
