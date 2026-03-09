// features/slots/screens/slot_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slot_wise_booking/screens/booking_confirm_screen.dart';
import 'package:slot_wise_booking/models/service_model.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/slot_provider.dart';

class SlotPickerScreen extends StatefulWidget {
  final ServiceModel service;
  const SlotPickerScreen({super.key, required this.service});
  @override
  State<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends State<SlotPickerScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay  = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load slots for today when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots(_selectedDay));
  }

  void _loadSlots(DateTime date) {
    context.read<SlotProvider>().fetchSlots(
      serviceId: widget.service.id,
      date: date,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.service.name)),
      body: Column(
        children: [
          // ── Calendar ──────────────────────────────────────────
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Color(0xFF1A5276), shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: Color(0xFF2E86C1), shape: BoxShape.circle),
            ),
            onDaySelected: (selected, focused) {
              setState(() { _selectedDay = selected; _focusedDay = focused; });
              _loadSlots(selected);
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Available Time Slots',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
            ),
          ),

          // ── Slot chips ────────────────────────────────────────
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
                        Text('No slots available on this day', style: TextStyle(color: Colors.grey)),
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
                      final isSelected = prov.selectedSlot?.id == slot.id;
                      return ChoiceChip(
                        label: Text(slot.displayTime),
                        selected: isSelected,
                        onSelected: (_) => prov.selectSlot(slot),
                        selectedColor: const Color(0xFF1A5276),
                        backgroundColor: const Color(0xFFD6EAF8),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1A5276),
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

      // ── Continue button ───────────────────────────────────────
      bottomNavigationBar: Consumer<SlotProvider>(
        builder: (ctx, prov, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: prov.selectedSlot == null ? null : () {
              Navigator.push(ctx, MaterialPageRoute(builder: (_) =>
                BookingConfirmScreen(
                  service: widget.service,
                  slot: prov.selectedSlot!,
                ),
              ));
            },
            child: const Text('Continue', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}