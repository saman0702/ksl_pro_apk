import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

const katianProNotificationChannel = AndroidNotificationChannel(
  'katian_pro_notifications',
  'Notifications Katian Pro',
  description: 'Alertes expéditions, bordereaux et flotte transporteur',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _localNotificationsReady = false;

Future<void> ensureLocalNotificationsReady() async {
  if (_localNotificationsReady) return;

  if (Platform.isAndroid) {
    final android = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(katianProNotificationChannel);
    await android?.requestNotificationsPermission();
  }

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  await _localNotificationsPlugin.initialize(settings: initSettings);
  _localNotificationsReady = true;
}

String _readTitle(RemoteMessage message) {
  return message.notification?.title?.trim().isNotEmpty == true
      ? message.notification!.title!.trim()
      : (message.data['title'] ?? message.data['Title'] ?? 'Katian Pro')
          .toString();
}

String _readBody(RemoteMessage message) {
  if (message.notification?.body?.trim().isNotEmpty == true) {
    return message.notification!.body!.trim();
  }
  return (message.data['body'] ??
          message.data['message'] ??
          message.data['Body'] ??
          '')
      .toString();
}

Future<void> displayKatianProSystemNotification(RemoteMessage message) async {
  final title = _readTitle(message);
  final body = _readBody(message);
  if (title.isEmpty && body.isEmpty) return;

  await ensureLocalNotificationsReady();

  final androidDetails = AndroidNotificationDetails(
    katianProNotificationChannel.id,
    katianProNotificationChannel.name,
    channelDescription: katianProNotificationChannel.description,
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    visibility: NotificationVisibility.public,
    ticker: title,
  );

  await _localNotificationsPlugin.show(
    id: message.hashCode.abs(),
    title: title,
    body: body.isNotEmpty ? body : title,
    notificationDetails: NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.entries.map((e) => '${e.key}=${e.value}').join('&'),
  );

  if (kDebugMode) {
    debugPrint('[Katian Pro Push] Notification système: $title');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await displayKatianProSystemNotification(message);
}
