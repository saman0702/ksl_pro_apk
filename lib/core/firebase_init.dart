import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../services/katian_notification_display.dart';

bool get isFirebaseConfigured {
  const placeholder = 'REPLACE_ME';
  final key = DefaultFirebaseOptions.android.apiKey;
  final appId = DefaultFirebaseOptions.android.appId;
  return key != placeholder &&
      !key.startsWith('REPLACE') &&
      appId != placeholder &&
      !appId.startsWith('REPLACE');
}

Future<void> initFirebaseEarly() async {
  if (kIsWeb || !isFirebaseConfigured) return;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (kDebugMode) {
      debugPrint('[Katian Pro] Firebase Core prêt');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[Katian Pro] Firebase Core échoué: $e\n$st');
    }
  }
}
