import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5KJa_AHZcBZiESTucFBfbIbsttoWpsDU',
    appId: '1:164237823299:web:16135fcb18eb11943833f6',
    messagingSenderId: '164237823299',
    projectId: 'takse-call',
    authDomain: 'takse-call.firebaseapp.com',
    storageBucket: 'takse-call.firebasestorage.app',
    measurementId: 'G-CDYPPEDCRY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATcNb1-l5iyUoWWlw-JR7wznrD9inWw-U',
    appId: '1:164237823299:android:a6e3bf1f9dba7b423833f6',
    messagingSenderId: '164237823299',
    projectId: 'takse-call',
    storageBucket: 'takse-call.firebasestorage.app',
  );
}
