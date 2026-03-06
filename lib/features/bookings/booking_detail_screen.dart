// lib/features/bookings/booking_detail_screen.dart
// View booking details and cancel option

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/booking_model.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;
  
  const BookingDetailScreen({
    super.key,
    required this.booking,
  });
  
  Future<void> _cancelBooking(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      final success = await context.read<BookingProvider>().cancelBooking(booking.id);
      
      if (!context.mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(); // Go back to bookings list
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: booking.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: booking.statusColor,
                    width: 2,
                  ),
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
            
            // Booking ID
            _buildDetailRow(
              icon: Icons.confirmation_number,
              label: 'Booking ID',
              value: '#${booking.id.toString().padLeft(6, '0')}',
            ),
            
            const Divider(height: 32),
            
            // Service
            _buildDetailRow(
              icon: Icons.spa,
              label: 'Service',
              value: booking.serviceName,
            ),
            
            const Divider(height: 32),
            
            // Date
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: booking.formattedDate,
            ),
            
            const Divider(height: 32),
            
            // Time
            _buildDetailRow(
              icon: Icons.access_time,
              label: 'Time',
              value: booking.formattedTimeRange,
            ),
            
            const Divider(height: 32),
            
            // Price
            _buildDetailRow(
              icon: Icons.payments,
              label: 'Price',
              value: booking.formattedPrice,
              isPrice: true,
            ),
            
            if (booking.notes != null) ...[
              const Divider(height: 32),
              _buildDetailRow(
                icon: Icons.note,
                label: 'Notes',
                value: booking.notes!,
              ),
            ],
            
            const Divider(height: 32),
            
            // Booked on
            _buildDetailRow(
              icon: Icons.schedule,
              label: 'Booked On',
              value: booking.createdAt.toString().split('.')[0],
            ),
            
            if (booking.cancelledAt != null) ...[
              const Divider(height: 32),
              _buildDetailRow(
                icon: Icons.cancel,
                label: 'Cancelled On',
                value: booking.cancelledAt.toString().split('.')[0],
              ),
            ],
          ],
        ),
      ),
      
      // Cancel button
      bottomNavigationBar: booking.canBeCancelled
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Consumer<BookingProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () => _cancelBooking(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Cancel Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }
  
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPrice = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isPrice ? FontWeight.bold : FontWeight.w600,
                  color: isPrice ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}