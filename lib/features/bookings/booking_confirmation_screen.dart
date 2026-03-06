// lib/features/bookings/booking_confirmation_screen.dart
// Review and confirm booking

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'my_bookings_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});
  
  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _notesController = TextEditingController();
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _confirmBooking() async {
    final service = context.read<ServiceProvider>().selectedService;
    final slot = context.read<BookingProvider>().selectedSlot;
    
    if (service == null || slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing booking information'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final success = await context.read<BookingProvider>().createBooking(
      serviceId: service.id,
      slotId: slot.id,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    
    if (!mounted) return;
    
    if (success) {
      // Clear selections
      context.read<BookingProvider>().clearSelectedSlot();
      context.read<ServiceProvider>().clearSelection();
      
      // Show success and navigate to bookings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        (route) => route.isFirst,
      );
    } else {
      final error = context.read<BookingProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Booking failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final service = context.watch<ServiceProvider>().selectedService;
    final slot = context.watch<BookingProvider>().selectedSlot;
    final isLoading = context.watch<BookingProvider>().isLoading;
    
    if (service == null || slot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Booking')),
        body: const Center(child: Text('Booking information not found')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Center(
              child: Text(
                'Review Your Booking',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Booking summary
            _buildSummaryCard(
              title: 'Service',
              value: service.name,
              icon: Icons.spa,
            ),
            
            _buildSummaryCard(
              title: 'Date',
              value: slot.formattedDate,
              icon: Icons.calendar_today,
            ),
            
            _buildSummaryCard(
              title: 'Time',
              value: slot.formattedTimeRange,
              icon: Icons.access_time,
            ),
            
            _buildSummaryCard(
              title: 'Duration',
              value: service.formattedDuration,
              icon: Icons.schedule,
            ),
            
            _buildSummaryCard(
              title: 'Price',
              value: service.formattedPrice,
              icon: Icons.payments,
              isPrice: true,
            ),
            
            const SizedBox(height: 24),
            
            // Optional notes
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Any special requests or preferences...',
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            // Confirm button
            CustomButton(
              text: 'Confirm Booking',
              icon: Icons.check,
              isLoading: isLoading,
              onPressed: _confirmBooking,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    bool isPrice = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
                  title,
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
      ),
    );
  }
}