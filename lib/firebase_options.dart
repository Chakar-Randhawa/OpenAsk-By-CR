import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Web options are sourced directly from project quaint-vector-3h7nb.
/// Android/iOS native configuration requires google-services.json / GoogleService-Info.plist
/// as documented in docs/NATIVE_SETUP.md.
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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyARKs9609d7VST895wGQCNQJrT9z4NJmXA',
    appId: '1:610793651298:web:18c60b4925120c43bd653b',
    messagingSenderId: '610793651298',
    projectId: 'quaint-vector-3h7nb',
    authDomain: 'quaint-vector-3h7nb.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyARKs9609d7VST895wGQCNQJrT9z4NJmXA',
    appId: '1:610793651298:android:openask_android_app',
    messagingSenderId: '610793651298',
    projectId: 'quaint-vector-3h7nb',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyARKs9609d7VST895wGQCNQJrT9z4NJmXA',
    appId: '1:610793651298:ios:openask_ios_app',
    messagingSenderId: '610793651298',
    projectId: 'quaint-vector-3h7nb',
    iosBundleId: 'com.openask.app',
  );
}
