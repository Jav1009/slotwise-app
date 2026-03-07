// lib/features/admin/manage_slots_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/service_model.dart';
import '../../data/models/slot_model.dart';
import '../../providers/service_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/utils/snackbar_utils.dart';

class ManageSlotsScreen extends StatefulWidget {
  const ManageSlotsScreen({super.key});

  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> {
  DateTime _focusedDay  = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ✅ FIX: Guard flags — same pattern as ManageServicesScreen
  bool _servicesFetched = false;
  bool _slotsFetched    = false;

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // ✅ FIX: Use didChangeDependencies instead of initState + Future.microtask
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_servicesFetched) {
      _servicesFetched = true;
      context.read<ServiceProvider>().fetchServices();
    }
    if (!_slotsFetched) {
      _slotsFetched = true;
      context.read<BookingProvider>().fetchAdminSlots(date: _fmtDate(_selectedDay));
    }
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay  = focused;
    });
    context.read<BookingProvider>().fetchAdminSlots(date: _fmtDate(selected));
  }

  Future<void> _confirmDeleteSlot(SlotModel slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot?'),
        content: Text('Delete the ${slot.startTime} slot? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    final provider = context.read<BookingProvider>();
    final success  = await provider.deleteSlot(slot.id);

    if (!mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(context, 'Slot deleted');
    } else {
      SnackbarUtils.showError(context, provider.error ?? 'Failed to delete slot');
      // Re-fetch to restore accurate state after a failed delete
      provider.fetchAdminSlots(date: _fmtDate(_selectedDay));
    }
  }

  void _openAddSlot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSlotSheet(
        selectedDate: _selectedDay,
        onCreated: () =>
            context.read<BookingProvider>().fetchAdminSlots(date: _fmtDate(_selectedDay)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Slots'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSlot,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Slot', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // ── Calendar ─────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay:  DateTime.now().add(const Duration(days: 90)),
              focusedDay:           _focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected:        _onDaySelected,
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                  formatButtonVisible: false, titleCentered: true),
            ),
          ),

          // ── Slot List ─────────────────────────────────────────
          // ✅ FIX: Builder gives a fresh BuildContext so context.watch works correctly
          Expanded(
            child: Builder(
              builder: (ctx) {
                final provider = ctx.watch<BookingProvider>();

                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.adminSlots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 8),
                        Text(provider.error!,
                            style: const TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ctx
                              .read<BookingProvider>()
                              .fetchAdminSlots(date: _fmtDate(_selectedDay)),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.adminSlots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No slots for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ctx
                      .read<BookingProvider>()
                      .fetchAdminSlots(date: _fmtDate(_selectedDay)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: provider.adminSlots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final slot = provider.adminSlots[i];
                      return _SlotTile(
                        slot:     slot,
                        onDelete: () => _confirmDeleteSlot(slot),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slot Tile ─────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  final SlotModel slot;
  final VoidCallback onDelete;
  const _SlotTile({required this.slot, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bool isBooked = !slot.isAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBooked
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.green.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isBooked ? Colors.orange : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${slot.startTime} – ${slot.endTime}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isBooked
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isBooked ? 'Booked' : 'Available',
              style: TextStyle(
                color: isBooked ? Colors.orange : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isBooked)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              tooltip: 'Delete slot',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

// ── Add Slot Bottom Sheet ─────────────────────────────────────

class _AddSlotSheet extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onCreated;
  const _AddSlotSheet({required this.selectedDate, required this.onCreated});

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  ServiceModel? _selectedService;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime   = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedService == null) {
      SnackbarUtils.showError(context, 'Please select a service');
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<BookingProvider>();
    final success  = await provider.createSlot(
      serviceId: _selectedService!.id,
      date:      DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      startTime: _fmtTime(_startTime),
      endTime:   _fmtTime(_endTime),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      widget.onCreated();
      SnackbarUtils.showSuccess(context, 'Slot created');
    } else {
      SnackbarUtils.showError(context, provider.error ?? 'Failed to create slot');
    }
  }

  @override
  Widget build(BuildContext context) {
    final services  = context.watch<ServiceProvider>().services;
    final dateLabel = DateFormat('EEE, MMM d yyyy').format(widget.selectedDate);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add Slot',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(dateLabel, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),

            DropdownButtonFormField<ServiceModel>(
              initialValue: _selectedService,
              hint: const Text('Select Service'),
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Service'),
              items: services
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedService = v),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Time', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      _startTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    leading: const Icon(Icons.access_time, color: AppColors.primary),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End Time', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      _endTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    leading: const Icon(Icons.access_time_filled, color: AppColors.primary),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create Slot',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}