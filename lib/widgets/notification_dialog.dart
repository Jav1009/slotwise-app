// lib/widgets/notification_dialog.dart
//
// Reusable notification sheet usable from any role (customer, staff, admin).
// Usage:
//   NotificationDialog.show(context);
//
// Features:
//   • Filter bar: All | Unread | Read
//   • Paginated — max 10 items per page with Previous/Next controls
//   • Mark single as read on tap
//   • Mark All Read button in header
//   • Unread dot badge on each unread item
//   • Pulls from NotificationProvider (already wired)
//   • Auto-fetches on open if list is empty

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

// ── Filter enum ────────────────────────────────────────────────────────────────
enum _NotifFilter { all, unread, read }

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({super.key});

  // ── Static convenience launcher ──────────────────────────
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<NotificationProvider>(),
        child: const NotificationDialog(),
      ),
    );
  }

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  _NotifFilter _filter  = _NotifFilter.all;
  int          _page    = 0;
  static const _perPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<NotificationProvider>();
      if (prov.notifications.isEmpty) prov.fetchNotifications();
    });
  }

  List<NotificationModel> _filtered(List<NotificationModel> all) {
    switch (_filter) {
      case _NotifFilter.unread: return all.where((n) => !n.isRead).toList();
      case _NotifFilter.read:   return all.where((n) =>  n.isRead).toList();
      case _NotifFilter.all:    return all;
    }
  }

  void _setFilter(_NotifFilter f) => setState(() { _filter = f; _page = 0; });

  @override
  Widget build(BuildContext context) {
    final c   = Theme.of(context).extension<SlotWiseColors>()!;
    final prov = context.watch<NotificationProvider>();
    final filtered = _filtered(prov.notifications);

    final totalPages = ((filtered.length) / _perPage).ceil().clamp(1, 999);
    final pageItems  = filtered.skip(_page * _perPage).take(_perPage).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize:     0.4,
      maxChildSize:     0.92,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text('Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: c.primaryColor,
                      )),
                  const Spacer(),
                  if (prov.unreadCount > 0)
                    TextButton.icon(
                      icon: Icon(Icons.done_all, size: 16, color: c.primaryColor),
                      label: Text('Mark all read',
                          style: TextStyle(fontSize: 12, color: c.primaryColor)),
                      onPressed: () => prov.markAllRead(),
                    ),
                ],
              ),
            ),

            // ── Filter chips ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _NotifFilter.values.map((f) {
                  final label = switch (f) {
                    _NotifFilter.all    => 'All (${prov.notifications.length})',
                    _NotifFilter.unread => 'Unread (${prov.unreadCount})',
                    _NotifFilter.read   => 'Read',
                  };
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _setFilter(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? c.primaryColor : c.accentSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? c.primaryColor : c.primaryColor.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : c.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: c.primaryColor.withOpacity(0.08)),

            // ── Content ──────────────────────────────────────
            Expanded(
              child: prov.isLoading
                  ? Center(child: CircularProgressIndicator(color: c.primaryColor))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 56, color: c.accentColor.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text(
                                _filter == _NotifFilter.unread
                                    ? 'No unread notifications'
                                    : 'No notifications yet',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scroll,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: c.primaryColor.withOpacity(0.06)),
                          itemBuilder: (_, i) => _NotifTile(
                            notif:   pageItems[i],
                            palette: c,
                            onTap: () {
                              if (!pageItems[i].isRead) {
                                prov.markAsRead(pageItems[i].id);
                              }
                            },
                          ),
                        ),
            ),

            // ── Pagination ────────────────────────────────────
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: const Text('Prev'),
                      onPressed: _page > 0
                          ? () => setState(() => _page--)
                          : null,
                    ),
                    Text(
                      'Page ${_page + 1} of $totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      label: const Text('Next'),
                      icon: const Icon(Icons.chevron_right, size: 18),
                      onPressed: _page < totalPages - 1
                          ? () => setState(() => _page++)
                          : null,
                    ),
                  ],
                ),
              ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ── Single notification tile ──────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final SlotWiseColors    palette;
  final VoidCallback      onTap;

  const _NotifTile({
    required this.notif,
    required this.palette,
    required this.onTap,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours   < 1)  return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notif.isRead;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot / read icon
            SizedBox(
              width: 36,
              child: isUnread
                  ? Container(
                      width: 10, height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: palette.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    )
                  : Icon(
                      Icons.notifications_none,
                      size: 20,
                      color: Colors.grey[400],
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.message,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                      color: isUnread
                          ? Theme.of(context).colorScheme.onBackground
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notif.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification icon button (use in AppBar + home header) ────────────────────
// Shows an animated badge with unread count.
// Usage:
//   NotificationIconButton()
//   NotificationIconButton(iconColor: Colors.white)

class NotificationIconButton extends StatelessWidget {
  final Color? iconColor;

  const NotificationIconButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();
    final c    = Theme.of(context).extension<SlotWiseColors>()!;
    final col  = iconColor ?? c.primaryColor;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => NotificationDialog.show(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            prov.unreadCount > 0
                ? Icons.notifications
                : Icons.notifications_none,
            color: col,
            size: 26,
          ),
          if (prov.unreadCount > 0)
            Positioned(
              right: -4,
              top:   -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF5350),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  prov.unreadCount > 99 ? '99+' : '${prov.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}