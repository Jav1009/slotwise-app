// features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationProvider>().fetchNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notif = context.watch<NotificationProvider>();
    final user = auth.user;

    // If we don't have a user (maybe just logged out or still loading),
    // avoid dereferencing null. Show a simple progress indicator or
    // navigate back to login.
    if (user == null) {
      // Optionally you could pushReplacementNamed('/login') here instead
      // of showing a spinner.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotifications(context, notif),
              ),
              if (notif.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${notif.unreadCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFD6EAF8),
              backgroundImage: user.profilePictureUrl != null
                  ? CachedNetworkImageProvider(user.profilePictureUrl!)
                        as ImageProvider
                  : null,
              child: user.profilePictureUrl == null
                  ? Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        color: Color(0xFF1A5276),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
            if (user.isAdmin)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6EAF8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: Color(0xFF1A5276),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 40),

            // My Bookings shortcut
            ListTile(
              leading: const Icon(Icons.book_online, color: Color(0xFF1A5276)),
              title: const Text('My Bookings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/my-bookings'),
            ),
            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await auth.logout();
                if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, NotificationProvider notif) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (notif.unreadCount > 0)
                  TextButton(
                    onPressed: notif.markAllRead,
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: notif.notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: notif.notifications.length,
                    itemBuilder: (_, i) {
                      final n = notif.notifications[i];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: n.isRead
                              ? Colors.grey[100]
                              : const Color(0xFFD6EAF8),
                          child: Icon(
                            Icons.notifications,
                            size: 16,
                            color: n.isRead
                                ? Colors.grey
                                : const Color(0xFF1A5276),
                          ),
                        ),
                        title: Text(
                          n.message,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        onTap: () => notif.markAsRead(n.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
