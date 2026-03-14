// lib/screens/staff/staff_dashboard_screen.dart
//
// UPDATED:
//   • Notification icon with badge in AppBar
//   • Settings icon → SettingsDialog
//   • Theme-aware via SlotWiseColors
//   • Restricted quick actions (staff cannot access User Management — admin only)
// Changes:
//   • Polling: startPolling() on AdminProvider + NotificationProvider every 30s
//     so badge and pending count update live without switching screens
//   • Logout: calls auth.logout() which clears _user first → no spinner hang
//   • Missed stat card added
//   • Today's booking tiles show formatted date (MMM d, yyyy)
//   • WidgetsBindingObserver: refreshes when app returns to foreground
//   • Logout button: calls auth.logout() then Navigator.pushNamedAndRemoveUntil('/login')
//     Root cause of stuck spinner — logout() only cleared _user, but the navigator
//     stack still had /staff on top of /. The Consumer<AuthProvider> at home: updated
//     the widget at / to LoginScreen, but /staff was never popped so it stayed visible.
//   • build(): user is read as nullable (user?) with null-guard — prevents the
//     force-unwrap crash during the one frame before navigation completes.
 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/routes/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_dialog.dart';
import '../../widgets/settings_dialog.dart';
import '../admin/manage_bookings_screen.dart';
import '../admin/manage_services_screen.dart';
import '../admin/manage_slots_screen.dart';
import '../customer/profile_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});
  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> with WidgetsBindingObserver {
  
  // Saved references — safe to call in dispose()
  AdminProvider?        _adminProvider;
  NotificationProvider? _notificationProvider;
 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adminProvider        = context.read<AdminProvider>();
    _notificationProvider = context.read<NotificationProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start polling — updates every 30s automatically
      context.read<AdminProvider>().startPolling();
      context.read<NotificationProvider>().startPolling();
    });
  }
 
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // context.read<AdminProvider>().fetchDashboardData();
      // context.read<NotificationProvider>().fetchNotifications();
      _adminProvider?.fetchDashboardData();
      _notificationProvider?.fetchNotifications();
    }
  }
 
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop polling when leaving dashboard
    // context.read<AdminProvider>().stopPolling();
    // context.read<NotificationProvider>().stopPolling();
     _adminProvider?.stopPolling();
    _notificationProvider?.stopPolling();
    super.dispose();
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, SlotWiseColors c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.primaryColor.withOpacity(0.08)),
        ),
        child: Column(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _quickAction(
      String label, IconData icon, VoidCallback onTap, SlotWiseColors c) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: c.primaryColor, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.primaryColor,
            ),
            textAlign: TextAlign.center),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c    = Theme.of(context).extension<SlotWiseColors>()!;
    // user can briefly be null during logout — return empty scaffold for that one frame
    // Flutter's home Consumer<AuthProvider> will immediately replace this with LoginScreen
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.firstName}'),
        actions: [
          const NotificationIconButton(iconColor: Colors.white),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => SettingsDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.goLogin();
            },
          ),
        ],
      ),

      body: Consumer<AdminProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) {
            return Center(child: CircularProgressIndicator(color: c.primaryColor));
          }

          final stats = prov.stats;
          return RefreshIndicator(
            color: c.primaryColor,
            onRefresh: prov.fetchDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Staff badge ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF4ADE80).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.badge_outlined,
                            size: 14, color: Color(0xFF2D5A27)),
                        SizedBox(width: 6),
                        Text(
                          'Staff Member',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D5A27),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats (row 1) ────────────────────────────
                  _SectionTitle("Today's Overview", c),
                  const SizedBox(height: 10),
                  Row(children: [
                    _statCard("Today's Bookings",
                        '${stats['today'] ?? 0}',
                        Icons.calendar_today_outlined,
                        c.primaryColor, c),
                    const SizedBox(width: 10),
                    _statCard('Pending',
                        '${stats['pending'] ?? 0}',
                        Icons.hourglass_empty_outlined,
                        AppColors.warning, c),
                  ]),
                  const SizedBox(height: 10),

                  // ── Stats (row 2) ────────────────────────────
                  Row(children: [
                    _statCard('Confirmed',
                        '${stats['confirmed'] ?? 0}',
                        Icons.check_circle_outline,
                        AppColors.success, c),
                    const SizedBox(width: 10),
                  ]),
                    // _statCard('Revenue',
                    //     'JMD \$${(stats['revenue'] ?? 0.0).toStringAsFixed(0)}',
                    //     Icons.attach_money,
                    //     AppColors.accent, c),

                  // ── Revenue (full width) ─────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.primaryColor.withOpacity(0.08)),
                    ),
                    child: Column(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.attach_money, color: AppColors.accent, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text('JMD \$${(stats['revenue'] ?? 0.0).toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.accent)),
                      const SizedBox(height: 3),
                      Text('Revenue (completed)',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // ── Quick Actions (staff — no user mgmt) ─────
                  _SectionTitle('Quick Actions', c),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickAction('Services', Icons.design_services_outlined,
                          () => Navigator.push(ctx, MaterialPageRoute(
                              builder: (_) => const ManageServicesScreen())), c),
                      _quickAction('Slots', Icons.schedule_outlined,
                          () => Navigator.push(ctx, MaterialPageRoute(
                              builder: (_) => const ManageSlotsScreen())), c),
                      _quickAction('Bookings', Icons.book_online_outlined,
                          () => Navigator.push(ctx, MaterialPageRoute(
                              builder: (_) => const ManageBookingsScreen())), c),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Today's Bookings ──────────────────────────
                  _SectionTitle("Today's Bookings", c),
                  const SizedBox(height: 8),

                  if (prov.allBookings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          Icon(Icons.event_available_outlined,
                              size: 48, color: c.primaryColor.withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text('No bookings today',
                              style: TextStyle(color: Colors.grey[500])),
                        ]),
                      ),
                    )
                  else
                    ...prov.allBookings.take(10).map(
                        (b) => _MiniBookingTile(booking: b, c: c)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _SectionTitle(String label, SlotWiseColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: c.primaryColor,
      ),
    ),
  );
}

class _MiniBookingTile extends StatelessWidget {
  final BookingModel   booking;
  final SlotWiseColors c;
  const _MiniBookingTile({required this.booking, required this.c});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(booking.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(booking.serviceName[0],
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ),
        title: Text(booking.serviceName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          // displayDate uses "Mar 12, 2026" format
          '${booking.startTime.substring(0, 5)}'
          ' — ${booking.customerName ?? booking.displayDate}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(booking.status,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}