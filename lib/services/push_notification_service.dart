import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'katian_notification_display.dart';

typedef PushRefreshCallback = Future<void> Function();
typedef PushTokenCallback = Future<void> Function(String token);
typedef PushDataCallback = void Function(Map<String, dynamic> data);

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging? _messaging;

  bool _initialized = false;
  String? _currentToken;
  PushRefreshCallback? onRefreshNotifications;
  void Function(Map<String, dynamic> data)? onNotificationOpened;
  PushDataCallback? onPushDataReceived;
  PushTokenCallback? onTokenRefreshed;

  String? get currentToken => _currentToken;
  bool get isReady => _initialized;

  bool get _firebaseConfigured {
    const placeholder = 'REPLACE_ME';
    return DefaultFirebaseOptions.android.apiKey != placeholder &&
        !DefaultFirebaseOptions.android.apiKey.startsWith('REPLACE') &&
        DefaultFirebaseOptions.android.appId != placeholder &&
        !DefaultFirebaseOptions.android.appId.startsWith('REPLACE');
  }

  Future<bool> initialize() async {
    if (_initialized) return true;
    if (kIsWeb || !_firebaseConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[Katian Pro Push] Firebase non configuré — notifications API uniquement.',
        );
      }
      return false;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _messaging = FirebaseMessaging.instance;
      await ensureLocalNotificationsReady();

      await _requestPermission();
      await _bindTokenListeners();
      _bindMessageListeners();

      _initialized = true;
      if (kDebugMode) {
        debugPrint('[Katian Pro Push] Initialisé — token=${_currentToken != null}');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Katian Pro Push] Init échouée: $e\n$st');
      }
      _messaging = null;
      return false;
    }
  }

  Future<void> _requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return;

    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _bindTokenListeners() async {
    final messaging = _messaging;
    if (messaging == null) return;

    _currentToken = await messaging.getToken();
    messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      onTokenRefreshed?.call(token);
    });
  }

  void _bindMessageListeners() {
    final messaging = _messaging;
    if (messaging == null) return;

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRemoteTap(message.data);
    });

    messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleRemoteTap(message.data);
      }
    });
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (message.data.isNotEmpty) {
      onPushDataReceived?.call(message.data);
    }
    await onRefreshNotifications?.call();
    await displayKatianProSystemNotification(message);
  }

  void _handleRemoteTap(Map<String, dynamic> data) {
    if (data.isNotEmpty) {
      onPushDataReceived?.call(data);
    }
    onNotificationOpened?.call(data);
  }

  Future<String?> refreshToken() async {
    if (!_initialized || _messaging == null) return null;
    _currentToken = await _messaging!.getToken();
    return _currentToken;
  }
}
