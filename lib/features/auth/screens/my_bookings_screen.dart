// features/bookings/screens/my_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../../../core/constants/app_colors.dart';

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

  Widget _buildList(List<BookingModel> items, bool showCancel) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No bookings here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _BookingCard(
        booking: items[i],
        onCancel: showCancel ? () => _showCancelDialog(items[i].id) : null,
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
  final VoidCallback? onCancel;
  const _BookingCard({required this.booking, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(booking.status);
    return Card(
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
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(booking.displayDateTime, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            const SizedBox(height: 4),
            Text('JMD \$${booking.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A5276))),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${booking.notes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red)),
                  child: const Text('Cancel Booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}