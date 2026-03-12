// features/bookings/screens/booking_confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import 'package:slot_wise_booking/models/slot_model.dart';
import '../../providers/booking_provider.dart';
import 'my_bookings_screen.dart';

class BookingConfirmScreen extends StatefulWidget {
  final ServiceModel service;
  final SlotModel    slot;
  const BookingConfirmScreen({super.key, required this.service, required this.slot});
  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _confirm() async {
    final prov = context.read<BookingProvider>();
    final ok   = await prov.createBooking(
      serviceId: widget.service.id,
      slotId:    widget.slot.id,
      notes:     _notesCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!'), backgroundColor: Colors.green),
      );
      // Navigate to My Bookings and clear the stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        (route) => route.isFirst,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error ?? 'Booking failed'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF1A5276), size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ]),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<BookingProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _infoRow(Icons.cut,      'Service',  widget.service.name),
                    _infoRow(Icons.calendar_today, 'Date', widget.slot.slotDate),
                    _infoRow(Icons.access_time,   'Time', widget.slot.displayTime),
                    _infoRow(Icons.attach_money,  'Price', widget.service.formattedPrice),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any special requests or information for the provider...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _confirm,
              child: isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}