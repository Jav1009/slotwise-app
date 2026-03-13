// features/bookings/screens/booking_confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  /// Format slot date → "March 13, 2026"
  String get _formattedDate {
    try {
      final d = DateFormat('yyyy-MM-dd').parse(widget.slot.slotDate);
      return DateFormat('MMMM d, yyyy').format(d);
    } catch (_) {
      return widget.slot.slotDate;
    }
  }
 
  /// Format current wall-clock time → "10:14 AM" (when user taps Confirm)
  /// The timeSLOT itself is shown separately.
  String get _bookingTime => DateFormat('hh:mm a').format(DateTime.now());

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
                    _infoRow(Icons.design_services_outlined, 'Service',  widget.service.name),
                    const Divider(height: 1),
                    // Date row — formatted "March 13, 2026"
                    _infoRow(Icons.calendar_today_outlined,  'Date',     _formattedDate),
                    const Divider(height: 1),
                    // Timeslot row — the selected appointment window
                    _infoRow(Icons.schedule_outlined,        'Timeslot', widget.slot.displayTime),
                    const Divider(height: 1),
                    // Booking time — wall clock at moment of confirmation
                    _infoRow(Icons.access_time_outlined,     'Booked at', _bookingTime),
                    const Divider(height: 1),
                    _infoRow(Icons.attach_money,             'Price',    widget.service.formattedPrice),
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

            // ── Confirm button ────────────────────────────────
            ElevatedButton(
              onPressed: isLoading ? null : _confirm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
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