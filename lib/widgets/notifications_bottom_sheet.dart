import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../models/app_notification.dart';
import '../providers/app_provider.dart';
import 'password_input_field.dart';

Future<void> showNotificationsBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const NotificationsBottomSheet(),
  );
}

String formatNotificationTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) return 'À l\'instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'Hier';
  return DateFormat('d MMM yyyy', 'fr_FR').format(dateTime);
}

class NotificationsBottomSheet extends StatefulWidget {
  const NotificationsBottomSheet({super.key});

  @override
  State<NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadNotifications();
    });
  }

  Future<void> _markAllRead(AppProvider app) async {
    await app.markAllNotificationsRead();
    if (!mounted) return;
    KatianToast.success(context, 'Toutes vos notifications sont lues.');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ext = context.katian;
    final items = app.notificationItems;
    final unreadCount = app.unreadNotificationCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: ext.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ext.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.notifications_outlined, color: ext.textPrimary, size: 26),
                          if (unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: KatianColors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: ext.textPrimary,
                            ),
                          ),
                          Text(
                            unreadCount > 0
                                ? '$unreadCount non lue${unreadCount > 1 ? 's' : ''}'
                                : 'Tout est à jour',
                            style: TextStyle(
                              fontSize: 13,
                              color: ext.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () => _markAllRead(app),
                        child: const Text('Tout lire'),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: ext.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: app.loadingNotifications && items.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: KatianColors.red),
                      )
                    : items.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune notification',
                              style: TextStyle(color: ext.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            color: KatianColors.red,
                            onRefresh: app.loadNotifications,
                            child: ListView.separated(
                              controller: scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final n = items[i];
                                return _NotificationTile(
                                  notification: n,
                                  onTap: () {
                                    if (!n.isRead) {
                                      app.markNotificationRead(n.id);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final n = notification;

    return Material(
      color: n.isRead ? ext.surface : ext.surface.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: n.isRead ? ext.border : n.accentColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: n.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(n.icon, color: n.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: ext.textPrimary,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: KatianColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: ext.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (n.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        formatNotificationTime(n.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: ext.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
