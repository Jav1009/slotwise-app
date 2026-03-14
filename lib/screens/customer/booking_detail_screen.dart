// lib/features/auth/screens/booking_detail_screen.dart
//
// NEW SCREEN — shows full details of a single booking.
// Accessible from MyBookingsScreen card tap.
// Shows: service name, date/time, price, status, notes.
// Actions: Cancel (if canCancel), Reschedule (if canReschedule).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/core/constants/app_colors.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import 'package:slot_wise_booking/providers/booking_provider.dart';
import 'package:slot_wise_booking/screens/customer/reschedule_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(booking.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status banner ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Column(children: [
                Icon(_statusIcon(booking.status), color: statusColor, size: 36),
                const SizedBox(height: 6),
                Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Details card ───────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _detailRow(Icons.design_services, 'Service', booking.serviceName),
                  if (booking.category != null)
                    _detailRow(Icons.category_outlined, 'Category', booking.displayCategory!),
                  _detailRow(Icons.calendar_today, 'Date', booking.displayDate),
                  _detailRow(Icons.access_time, 'Time', booking.displayTime),
                  _detailRow(Icons.attach_money, 'Price', 'JMD \$${booking.price.toStringAsFixed(2)}'),
                  _detailRow(Icons.tag, 'Booking ID', '#${booking.id}'),
                  _detailRow(Icons.schedule, 'Booked on',
                    _formatDate(booking.createdAt)),
                  if (booking.notes != null && booking.notes!.isNotEmpty)
                    _detailRow(Icons.notes, 'Notes', booking.notes!),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // ── Actions ────────────────────────────────────────
            if (booking.canReschedule) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Reschedule', style: TextStyle(fontSize: 16)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RescheduleScreen(
                      booking: booking,
                      // Build a minimal ServiceModel for the slot picker
                      service: ServiceModel(
                        id:              booking.serviceId,
                        name:            booking.serviceName,
                        durationMinutes: 0, // not needed for reschedule
                        price:           booking.price,
                        category:        booking.category!,
                        isActive:        true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (booking.canCancel)
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Cancel Booking',
                    style: TextStyle(fontSize: 16, color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () => _confirmCancel(context),
              ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':  return Icons.check_circle_outline;
      case 'completed':  return Icons.task_alt;
      case 'cancelled':  return Icons.cancel_outlined;
      case 'missed':     return Icons.event_busy_outlined;
      default:           return Icons.hourglass_empty;
    }
  }

  /// Formats a DateTime as "Mar 14, 2026" — consistent with BookingModel.displayDate
  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value,  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
            'Are you sure you want to cancel this booking? The slot will be freed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await context.read<BookingProvider>().cancelBooking(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Booking cancelled.' : 'Could not cancel booking.'),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
        ));
        if (ok) Navigator.pop(context);
      }
    }
  }
}