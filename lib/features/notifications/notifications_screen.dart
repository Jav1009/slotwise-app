// lib/features/notifications/notifications_screen.dart
// User-only screen. No admin logic here.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  Future<void> _markAllRead() async {
    final success =
        await context.read<NotificationProvider>().markAllAsRead();
    if (mounted) {
      success
          ? SnackbarUtils.showSuccess(
              context, 'All notifications marked as read')
          : SnackbarUtils.showError(
              context, 'Failed to mark notifications as read');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, notif, _) {
              if (notif.unreadCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all,
                    color: Colors.white, size: 18),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(provider.error!,
                      style: const TextStyle(
                          color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ctx
                        .read<NotificationProvider>()
                        .fetchNotifications(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Booking updates will appear here',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ctx.read<NotificationProvider>().fetchNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final n = provider.notifications[i];
                return _NotificationTile(
                  notification: n,
                  isDark: isDark,
                  onTap: () {
                    // Simply mark as read — no navigation needed.
                    // The user can see booking details via My Bookings.
                    if (!n.isRead) {
                      ctx
                          .read<NotificationProvider>()
                          .markAsRead(n.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'booking_created':   return Icons.bookmark_add_outlined;
      case 'booking_confirmed': return Icons.check_circle_outline;
      case 'booking_cancelled': return Icons.cancel_outlined;
      case 'status_update':     return Icons.update_outlined;
      case 'reminder':          return Icons.alarm_outlined;
      default:                  return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'booking_created':   return AppColors.primary;
      case 'booking_confirmed': return AppColors.confirmed;
      case 'booking_cancelled': return AppColors.cancelled;
      case 'status_update':     return AppColors.accent;
      case 'reminder':          return AppColors.warning;
      default:                  return AppColors.textSecondary;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread    = !notification.isRead;
    final bgColor     = isUnread
        ? AppColors.primary.withOpacity(isDark ? 0.12 : 0.05)
        : Colors.transparent;
    final messageColor = isDark ? Colors.white : AppColors.textPrimary;
    final timeColor    = isDark ? Colors.white54 : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: messageColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: TextStyle(fontSize: 12, color: timeColor),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}