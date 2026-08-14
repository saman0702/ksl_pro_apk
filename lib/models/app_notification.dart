import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
    this.expeditionId,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final int? expeditionId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['created_at'];
    if (raw is String && raw.isNotEmpty) {
      created = DateTime.tryParse(raw);
    }
    return AppNotification(
      id: json['id'] as int,
      title: (json['title'] as String? ?? '').trim(),
      message: (json['message'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? 'info').trim(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: created,
      expeditionId: json['expedition_id'] as int?,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      expeditionId: expeditionId,
    );
  }

  IconData get icon {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      default:
        if (title.toLowerCase().contains('bordereau') ||
            title.toLowerCase().contains('expédition') ||
            title.toLowerCase().contains('colis')) {
          return Icons.local_shipping_outlined;
        }
        return Icons.notifications_outlined;
    }
  }

  Color get accentColor {
    switch (type) {
      case 'success':
        return KatianColors.green;
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'error':
        return KatianColors.red;
      default:
        return KatianColors.red;
    }
  }
}
