import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/slot_provider.dart';
import '../../providers/service_provider.dart';
import '../../models/service.dart';
import '../../models/slot.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/constants/routes.dart';
import '../../core/utils/formatters.dart';

class SlotPickerScreen extends StatefulWidget {
  final Service service;

  const SlotPickerScreen({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends State<SlotPickerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Slot? _selectedSlot;
  Map<DateTime, List<Slot>> _groupedSlots = {};

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  void _loadSlots() {
    final slotProvider = Provider.of<SlotProvider>(context, listen: false);
    slotProvider.fetchSlots(
      widget.service.id,
      Formatters.formatApiDate(_selectedDay),
    );
  }

  void _groupSlotsByDate(List<Slot> slots) {
    _groupedSlots = {};
    for (var slot in slots) {
      final date = DateTime(slot.date.year, slot.date.month, slot.date.day);
      if (_groupedSlots[date] == null) {
        _groupedSlots[date] = [];
      }
      _groupedSlots[date]!.add(slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date & Time'),
      ),
      body: Consumer<SlotProvider>(
        builder: (context, slotProvider, child) {
          if (!slotProvider.isLoading && slotProvider.availableSlots.isNotEmpty) {
            _groupSlotsByDate(slotProvider.availableSlots);
          }

          return Column(
            children: [
              // Calendar
              Card(
                margin: const EdgeInsets.all(16),
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 60)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedSlot = null;
                    });
                    slotProvider.fetchSlots(
                      widget.service.id,
                      Formatters.formatApiDate(selectedDay),
                    );
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(fontSize: 14),
                    weekendTextStyle: const TextStyle(fontSize: 14),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      // Show indicator for days with available slots
                      if (_groupedSlots.containsKey(date) && 
                          _groupedSlots[date]!.any((slot) => slot.isAvailable)) {
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),

              // Time slots header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Slots',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isSameDay(_selectedDay, DateTime.now())
                            ? 'Today'
                            : Formatters.formatDate(_selectedDay),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Time slots grid
              Expanded(
                child: slotProvider.isLoading
                    ? const LoadingIndicator()
                    : slotProvider.availableSlots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No slots available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try selecting another date',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildTimeSlotsGrid(slotProvider.availableSlots),
              ),

              // Bottom button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomButton(
                  text: 'Continue',
                  onPressed: _selectedSlot == null
                      ? null
                      : () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.bookingConfirm,
                            arguments: {
                              'service': widget.service,
                              'slot': _selectedSlot,
                            },
                          );
                        },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotsGrid(List<Slot> slots) {
    final availableSlots = slots.where((slot) => slot.isAvailable).toList();
    
    if (availableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No available slots',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: availableSlots.length,
      itemBuilder: (context, index) {
        final slot = availableSlots[index];
        final isSelected = _selectedSlot?.id == slot.id;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedSlot = slot;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.displayStartTime,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}