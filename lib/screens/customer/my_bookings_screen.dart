// features/bookings/screens/my_bookings_screen.dart
//
// Changes:
//   • Card is now tappable → navigates to BookingDetailScreen
//   • Added Reschedule button on upcoming bookings (alongside Cancel)
//   • Pull-to-refresh present on all tabs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import 'package:slot_wise_booking/screens/customer/booking_detail_screen.dart';
import 'package:slot_wise_booking/screens/customer/reschedule_screen.dart';
import '../../providers/booking_provider.dart';
import '../../core/constants/app_colors.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<BookingProvider>().fetchMyBookings());
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _showCancelDialog(int bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? The slot will be freed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await context.read<BookingProvider>().cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Booking cancelled.' : 'Could not cancel booking.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ));
      }
    }
  }

  Widget _buildList(List<BookingModel> items, bool showActions) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              showActions ? 'No upcoming bookings' : 'Nothing here yet',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: context.read<BookingProvider>().fetchMyBookings,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _BookingCard(
          booking:     items[i],
          showActions: showActions,
          onCancel:    () => _showCancelDialog(items[i].id),
          onReschedule: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => RescheduleScreen(
                booking: items[i],
                service: ServiceModel(
                  id:              items[i].serviceId,
                  name:            items[i].serviceName,
                  durationMinutes: 0,
                  price:           items[i].price,
                  category:        items[i].category!,
                  isActive:        true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past'), Tab(text: 'Cancelled')],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          return TabBarView(
            controller: _tabs,
            children: [
              _buildList(prov.upcoming,  true),
              _buildList(prov.past,      false),
              _buildList(prov.cancelled, false),
            ],
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool         showActions;
  final VoidCallback? onCancel;
  final VoidCallback onReschedule;
  const _BookingCard({required this.booking, required this.showActions, required this.onCancel, required this.onReschedule});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(booking.status);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(booking.serviceName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(booking.status.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 8),

              // Date/time
              Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(booking.displayDateTime, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              const SizedBox(height: 4),

              // Price
              Text('JMD \$${booking.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A5276))),
              
              // Category
              Text('Category: ${booking.category}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A5276))),
              
              // Notes
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Note: ${booking.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],

              // Action buttons
              if (showActions && booking.isUpcoming) ...[
                const SizedBox(height: 12),
                Row(children: [
                  // Reschedule
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                      label: const Text('Reschedule'),
                      onPressed: onReschedule,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Cancel
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: Colors.red),
                      label: const Text('Cancel',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                      onPressed: onCancel,
                    ),
                  ),
                ]),
              ],

              // Hint to tap for details
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('View details',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}