// lib/features/bookings/slot_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/service_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/slot_model.dart';
import 'booking_confirmation_screen.dart';

class SlotPickerScreen extends StatefulWidget {
  const SlotPickerScreen({super.key});

  @override
  State<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends State<SlotPickerScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  void _loadSlots() {
    final service = context.read<ServiceProvider>().selectedService;
    if (service != null) {
      context.read<BookingProvider>().fetchAvailableSlots(
            service.id,
            _selectedDate,
          );
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    final service         = context.watch<ServiceProvider>().selectedService;
    final bookingProvider = context.watch<BookingProvider>();
    final isDark          = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colours
    final headerBg   = isDark ? const Color(0xFF1E1E1E) : AppColors.surface;
    final _     = isDark ? const Color(0xFF2C2C2C) : AppColors.background;
    final dayText    = isDark ? Colors.white : Colors.black;
    final dateText   = isDark ? Colors.white70 : AppColors.textSecondary;
    final arrowBg    = isDark ? const Color(0xFF3A3A3A) : AppColors.background;
    final arrowColor = isDark ? Colors.white70 : null;

    if (service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Time')),
        body: const Center(child: Text('Service not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Time')),
      body: Column(
        children: [
          // ── Date selector ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: headerBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: dayText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeDate(-1),
                      icon: Icon(Icons.chevron_left, color: arrowColor),
                      style: IconButton.styleFrom(
                          backgroundColor: arrowBg),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEEE').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: dayText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, y')
                                  .format(_selectedDate),
                              style: TextStyle(
                                  fontSize: 14, color: dateText),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeDate(1),
                      icon: Icon(Icons.chevron_right,
                          color: arrowColor),
                      style: IconButton.styleFrom(
                          backgroundColor: arrowBg),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Time slots ───────────────────────────────────
          Expanded(
            child: bookingProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookingProvider.availableSlots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: dateText),
                            const SizedBox(height: 16),
                            Text(
                              'No available slots',
                              style: TextStyle(
                                  fontSize: 18, color: dateText),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try selecting a different date',
                              style: TextStyle(
                                  fontSize: 14, color: dateText),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount:
                            bookingProvider.availableSlots.length,
                        itemBuilder: (context, index) {
                          final slot =
                              bookingProvider.availableSlots[index];
                          return _SlotChip(
                            slot: slot,
                            isDark: isDark,
                            isSelected:
                                bookingProvider.selectedSlot?.id ==
                                    slot.id,
                            onTap: () =>
                                bookingProvider.selectSlot(slot),
                          );
                        },
                      ),
          ),
        ],
      ),

      // ── Continue button ──────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: bookingProvider.selectedSlot != null
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const BookingConfirmationScreen(),
                      ),
                    )
                : null,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Continue',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// ── Slot chip ─────────────────────────────────────────────────

class _SlotChip extends StatelessWidget {
  final SlotModel slot;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Unselected background adapts to theme
    final unselectedBg     = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final unselectedBorder = isDark ? const Color(0xFF3A3A3A) : AppColors.divider;
    final unselectedText   = isDark ? Colors.white : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : unselectedBg,
          border: Border.all(
            color: isSelected ? AppColors.primary : unselectedBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            slot.formattedStartTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : unselectedText,
            ),
          ),
        ),
      ),
    );
  }
}