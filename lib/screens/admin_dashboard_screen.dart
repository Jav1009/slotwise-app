// features/admin/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import '../providers/admin_provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'manage_services_screen.dart';
import 'manage_slots_screen.dart';
import 'manage_bookings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<AdminProvider>().fetchDashboardData());
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        CircleAvatar(
          radius: 28, backgroundColor: AppColors.lightBlue,
          child: Icon(icon, color: AppColors.primary)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          final stats = prov.stats;
          return RefreshIndicator(
            onRefresh: prov.fetchDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 12),

                  // Stats row 1
                  Row(children: [
                    _statCard('Bookings Today', '${stats['today'] ?? 0}',
                      Icons.calendar_today, AppColors.primary),
                    const SizedBox(width: 8),
                    _statCard('Pending', '${stats['pending'] ?? 0}',
                      Icons.hourglass_empty, AppColors.warning),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _statCard('Confirmed', '${stats['confirmed'] ?? 0}',
                      Icons.check_circle_outline, AppColors.success),
                    const SizedBox(width: 8),
                    _statCard('Revenue', 'JMD \$${(stats['revenue'] ?? 0.0).toStringAsFixed(0)}',
                      Icons.attach_money, AppColors.accent),
                  ]),

                  const SizedBox(height: 24),
                  const Text('Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickAction('Services', Icons.design_services, () => Navigator.push(ctx,
                          MaterialPageRoute(builder: (_) => const ManageServicesScreen()))),
                      _quickAction('Slots', Icons.schedule, () => Navigator.push(ctx,
                          MaterialPageRoute(builder: (_) => const ManageSlotsScreen()))),
                      _quickAction('Bookings', Icons.book_online, () => Navigator.push(ctx,
                          MaterialPageRoute(builder: (_) => const ManageBookingsScreen()))),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text("Today's Bookings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),

                  if (prov.allBookings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No bookings today', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ...prov.allBookings.take(5).map((b) => _MiniBookingTile(booking: b)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniBookingTile extends StatelessWidget {
  final BookingModel booking;
  const _MiniBookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(booking.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(booking.serviceName[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${booking.startTime.substring(0,5)} — ${booking.slotDate}'),
        trailing: Chip(
          label: Text(booking.status, style: TextStyle(color: color, fontSize: 11)),
          backgroundColor: color.withOpacity(0.1),
          side: BorderSide(color: color),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}