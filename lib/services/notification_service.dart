import 'package:dio/dio.dart';

import '../models/app_notification.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService(this._api);

  final ApiClient _api;

  Future<NotificationListResult> fetchNotifications({int limit = 50}) async {
    final res = await _api.dio.get(
      '/notifications/',
      queryParameters: {'limit': limit},
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['notifications'] as List<dynamic>? ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationListResult(
      notifications: items,
      unreadCount: data['unread_count'] as int? ?? 0,
    );
  }

  Future<int> fetchUnreadCount() async {
    final res = await _api.dio.get('/notifications/unread-count/');
    return (res.data as Map<String, dynamic>)['unread_count'] as int? ?? 0;
  }

  Future<int> markRead(int notificationId) async {
    final res = await _api.dio.post('/notifications/$notificationId/read/');
    return (res.data as Map<String, dynamic>)['unread_count'] as int? ?? 0;
  }

  Future<int> markAllRead() async {
    final res = await _api.dio.post('/notifications/read-all/');
    return (res.data as Map<String, dynamic>)['unread_count'] as int? ?? 0;
  }

  Future<void> registerDevice({
    required String token,
    required String platform,
    String deviceName = '',
  }) async {
    await _api.dio.post('/notifications/register-device/', data: {
      'token': token,
      'platform': platform,
      'device_name': deviceName,
    });
  }

  Future<void> unregisterDevice(String token) async {
    try {
      await _api.dio.post('/notifications/unregister-device/', data: {
        'token': token,
      });
    } on DioException catch (_) {}
  }
}

class NotificationListResult {
  NotificationListResult({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
}
