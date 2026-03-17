// lib/features/bookings/booking_detail_screen.dart
// View booking details and cancel option

// lib/features/bookings/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/booking_model.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  Future<void> _cancelBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await context.read<BookingProvider>().cancelBooking(booking.id);
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final error = context.read<BookingProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to cancel booking'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use theme-aware colours everywhere
    final _       = Theme.of(context).colorScheme;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final labelColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final valueColor = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: booking.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: booking.statusColor, width: 2),
                ),
                child: Text(
                  booking.statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: booking.statusColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            _buildDetailRow(
              context: context,
              icon: Icons.confirmation_number,
              label: 'Booking ID',
              value: '#${booking.id.toString().padLeft(6, '0')}',
              cardColor: cardColor,
              labelColor: labelColor,
              valueColor: valueColor,
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context: context,
              icon: Icons.spa,
              label: 'Service',
              value: booking.serviceName,
              cardColor: cardColor,
              labelColor: labelColor,
              valueColor: valueColor,
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context: context,
              icon: Icons.calendar_today,
              label: 'Date',
              value: booking.formattedDate,
              cardColor: cardColor,
              labelColor: labelColor,
              valueColor: valueColor,
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context: context,
              icon: Icons.access_time,
              label: 'Time',
              value: booking.formattedTimeRange,
              cardColor: cardColor,
              labelColor: labelColor,
              valueColor: valueColor,
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context: context,
              icon: Icons.payments,
              label: 'Price',
              value: booking.formattedPrice,
              isPrice: true,
              cardColor: cardColor,
              labelColor: labelColor,
              valueColor: valueColor,
            ),
            if (booking.notes != null) ...[
              const Divider(height: 32),
              _buildDetailRow(
                context: context,
                icon: Icons.note,
                label: 'Notes',
                value: booking.notes!,
                cardColor: cardColor,
                labelColor: labelColor,
                valueColor: valueColor,
              ),
            ],
            const Divider(height: 32),
            _buildDetailRow(
              context: context,
              icon: Icons.schedule,
              label: 'Booked On',
              value: booking.createdAt.toString().split('.')[0],
              cardColor: cardColor,
              labelColor: labelColor,
              valueColor: valueColor,
            ),
            if (booking.cancelledAt != null) ...[
              const Divider(height: 32),
              _buildDetailRow(
                context: context,
                icon: Icons.cancel,
                label: 'Cancelled On',
                value: booking.cancelledAt.toString().split('.')[0],
                cardColor: cardColor,
                labelColor: labelColor,
                valueColor: valueColor,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: booking.canBeCancelled
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Consumer<BookingProvider>(
                  builder: (ctx, provider, _) => ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => _cancelBooking(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Cancel Booking',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color cardColor,
    required Color labelColor,
    required Color valueColor,
    bool isPrice = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: labelColor)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      isPrice ? FontWeight.bold : FontWeight.w600,
                  color: isPrice ? AppColors.primary : valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}