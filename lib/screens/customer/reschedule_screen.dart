// lib/features/auth/screens/reschedule_screen.dart
//
// NEW SCREEN — allows a customer to move their booking to a new slot.
// Reuses the same calendar + slot chip UI as SlotPickerScreen.
// On confirm → calls BookingProvider.rescheduleBooking().

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/providers/booking_provider.dart';
import 'package:slot_wise_booking/providers/slot_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:slot_wise_booking/core/constants/app_colors.dart';
import 'package:slot_wise_booking/models/booking_model.dart';
import 'package:slot_wise_booking/models/service_model.dart';

class RescheduleScreen extends StatefulWidget {
  final BookingModel booking;
  final ServiceModel service;
  const RescheduleScreen({super.key, required this.booking, required this.service});

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay  = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots(_selectedDay));
  }

  void _loadSlots(DateTime date) {
    context.read<SlotProvider>().fetchSlots(
      serviceId: widget.service.id,
      date: date,
    );
  }

  Future<void> _confirm() async {
    final slotProv    = context.read<SlotProvider>();
    final bookingProv = context.read<BookingProvider>();
    final newSlot     = slotProv.selectedSlot;

    if (newSlot == null) return;

    // Warn if trying to book same slot
    if (newSlot.id == widget.booking.slotId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is already your current slot. Please choose a different time.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Reschedule'),
        content: Text(
          'Move your ${widget.booking.serviceName} booking to '
          '${newSlot.slotDate} at ${newSlot.displayTime}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await bookingProv.rescheduleBooking(
      bookingId:  widget.booking.id,
      newSlotId:  newSlot.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Booking rescheduled to ${newSlot.slotDate} at ${newSlot.displayTime}'
          : (bookingProv.error ?? 'Reschedule failed')),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ));

    if (ok) {
      // Pop both RescheduleScreen and BookingDetailScreen to refresh list
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reschedule — ${widget.booking.serviceName}')),
      body: Column(
        children: [
          // Current booking info
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current: ${widget.booking.slotDate} at ${widget.booking.displayTime}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ]),
          ),

          // Calendar
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: Color(0xFF2E86C1), shape: BoxShape.circle),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay  = focused;
              });
              _loadSlots(selected);
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Available Slots',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
          ),

          // Slot chips
          Expanded(
            child: Consumer<SlotProvider>(
              builder: (ctx, prov, _) {
                if (prov.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (prov.slots.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No slots available on this day',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: prov.slots.map((slot) {
                      final isSelected   = prov.selectedSlot?.id == slot.id;
                      final isCurrent    = slot.id == widget.booking.slotId;
                      return ChoiceChip(
                        label: Text(isCurrent
                            ? '${slot.displayTime} (current)'
                            : slot.displayTime),
                        selected: isSelected,
                        onSelected: isCurrent ? null : (_) => prov.selectSlot(slot),
                        selectedColor: AppColors.primary,
                        backgroundColor: isCurrent ? Colors.grey[200] : AppColors.lightBlue,
                        labelStyle: TextStyle(
                          color: isCurrent
                              ? Colors.grey
                              : (isSelected ? Colors.white : AppColors.primary),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Confirm button
      bottomNavigationBar: Consumer<SlotProvider>(
        builder: (ctx, prov, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: prov.selectedSlot == null ? null : _confirm,
            child: context.watch<BookingProvider>().isLoading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm Reschedule', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}