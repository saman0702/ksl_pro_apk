/// Configuration Firebase — projet Katian Pro (`katian-pro-expedition`).
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web non configuré pour Katian Pro.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase non configuré pour ${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBiaBjTeAlrUK5zl5aoTQpXt8Fj-GqNX8',
    appId: '1:838402392502:android:695bdf025dfe8de8af0117',
    messagingSenderId: '838402392502',
    projectId: 'katian-pro-expedition',
    storageBucket: 'katian-pro-expedition.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME_IOS',
    appId: 'REPLACE_ME_IOS',
    messagingSenderId: '838402392502',
    projectId: 'katian-pro-expedition',
    storageBucket: 'katian-pro-expedition.firebasestorage.app',
    iosBundleId: 'com.katian.katianProCompagnietpApp',
  );
}
