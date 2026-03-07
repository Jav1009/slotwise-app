import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({
    Key? key,
    required this.notification,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: notification.isRead ? null : notification.backgroundColor,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notification.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 20,
              ),
            ),
            title: Text(
              notification.typeText,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: notification.isRead
                ? null
                : Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: () async {
              if (!notification.isRead) {
                await notificationProvider.markAsRead(notification.id);
              }
              if (onTap != null) {
                onTap!();
              }
            },
          ),
        );
      },
    );
  }
}