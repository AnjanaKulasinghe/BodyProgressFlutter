import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:  return android;
      case TargetPlatform.iOS:      return ios;
      case TargetPlatform.macOS:    return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions is not supported for this platform.',
        );
    }
  }

  // ⚠️ These values were extracted from your iOS project's GoogleService-Info.plist.
  // Note: Android App ID and API Keys are placeholders. You should create an Android
  // app in the Firebase Console and replace the Android options below when ready to run on Android.

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqRKs7JeF8h54LHnjdJPigOCDo_--UFQQ',
    appId: '1:1025310020594:web:firebase', // Placeholder
    messagingSenderId: '1025310020594',
    projectId: 'bodyprogressapp-24a1a',
    storageBucket: 'bodyprogressapp-24a1a.firebasestorage.app',
    authDomain: 'bodyprogressapp-24a1a.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCL3Y7xXaRH3OJK56on2KNJ_sWPKko9O-o', 
    appId: '1:1025310020594:android:56422226eafacc96d6116b',
    messagingSenderId: '1025310020594',
    projectId: 'bodyprogressapp-24a1a',
    storageBucket: 'bodyprogressapp-24a1a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqRKs7JeF8h54LHnjdJPigOCDo_--UFQQ',
    appId: '1:1025310020594:ios:12a1ce10666b9943d6116b',
    messagingSenderId: '1025310020594',
    projectId: 'bodyprogressapp-24a1a',
    storageBucket: 'bodyprogressapp-24a1a.firebasestorage.app',
    iosBundleId: 'AJ-Games.BodyProgressApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAqRKs7JeF8h54LHnjdJPigOCDo_--UFQQ',
    appId: '1:1025310020594:ios:12a1ce10666b9943d6116b',
    messagingSenderId: '1025310020594',
    projectId: 'bodyprogressapp-24a1a',
    storageBucket: 'bodyprogressapp-24a1a.firebasestorage.app',
    iosBundleId: 'AJ-Games.BodyProgressApp',
  );
}
