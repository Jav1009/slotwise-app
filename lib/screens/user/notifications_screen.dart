import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_tile.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../core/constants/routes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.fetchNotifications();
  }

  Future<void> _markAllAsRead() async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await notificationProvider.markAllAsRead();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unread'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading && notificationProvider.notifications.isEmpty) {
            return const LoadingIndicator();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Unread tab
              notificationProvider.unreadNotifications.isEmpty
                  ? EmptyState(
                      icon: Icons.notifications_off,
                      message: 'No unread notifications',
                      subtitle: 'You\'re all caught up!',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: notificationProvider.unreadNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = notificationProvider.unreadNotifications[index];
                          return NotificationTile(
                            notification: notification,
                            onTap: () {
                              if (notification.bookingId != null) {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.bookingDetail,
                                  arguments: notification.bookingId,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
              
              // All notifications tab
              notificationProvider.notifications.isEmpty
                  ? EmptyState(
                      icon: Icons.notifications_off,
                      message: 'No notifications',
                      subtitle: 'Your notifications will appear here',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: notificationProvider.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notificationProvider.notifications[index];
                          return NotificationTile(
                            notification: notification,
                            onTap: () {
                              if (notification.bookingId != null) {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.bookingDetail,
                                  arguments: notification.bookingId,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}