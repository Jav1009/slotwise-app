// lib/features/admin/manage_slots_screen.dart
// Key addition: _BulkSlotSheet — generates slots at a chosen interval
// across a time range, sends each to the backend, reports results.

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
import '../../widgets/admin_theme_wrapper.dart';
import 'bulk_slots_screen.dart';

class ManageSlotsScreen extends StatefulWidget {
  const ManageSlotsScreen({super.key});
  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _servicesFetched = false;
  bool _slotsFetched = false;

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_servicesFetched) {
      _servicesFetched = true;
      context.read<ServiceProvider>().fetchServices();
    }
    if (!_slotsFetched) {
      _slotsFetched = true;
      context.read<BookingProvider>().fetchAdminSlots(
        date: _fmtDate(_selectedDay),
      );
    }
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    context.read<BookingProvider>().fetchAdminSlots(date: _fmtDate(selected));
  }

  Future<void> _confirmDeleteSlot(SlotModel slot) async {
    final confirmed = await showAdminDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot?'),
        content: Text(
          'Delete the ${_fmt(slot.startTime)} slot? This cannot be undone.',
        ),
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
    if (!mounted || confirmed != true) return;
    final provider = context.read<BookingProvider>();
    final success = await provider.deleteSlot(slot.id);
    if (!mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(context, 'Slot deleted');
    } else {
      SnackbarUtils.showError(
        context,
        provider.error ?? 'Failed to delete slot',
      );
      provider.fetchAdminSlots(date: _fmtDate(_selectedDay));
    }
  }

  void _openAddSlotMenu() {
    showAdminDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add Slots'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _openSingleSlotSheet();
            },
            child: const ListTile(
              leading: Icon(Icons.add_circle_outline, color: AppColors.primary),
              title: Text('Single Slot'),
              subtitle: Text('Add one specific time slot'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _openBulkSlotSheet();
            },
            child: const ListTile(
              leading: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
              ),
              title: Text('Bulk Generate (This Day)'),
              subtitle: Text('Fill the selected day with slots automatically'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BulkSlotScreen()),
              );
            },
            child: const ListTile(
              leading: Icon(Icons.date_range_rounded, color: AppColors.primary),
              title: Text('Bulk Generate (Date Range)'),
              subtitle: Text('Create slots across multiple days at once'),
            ),
          ),
        ],
      ),
    );
  }

  void _openSingleSlotSheet() {
    showAdminBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSlotSheet(
        selectedDate: _selectedDay,
        onCreated: () => context.read<BookingProvider>().fetchAdminSlots(
          date: _fmtDate(_selectedDay),
        ),
      ),
    );
  }

  void _openBulkSlotSheet() {
    showAdminBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BulkSlotSheet(
        selectedDate: _selectedDay,
        onCreated: () => context.read<BookingProvider>().fetchAdminSlots(
          date: _fmtDate(_selectedDay),
        ),
      ),
    );
  }

  // Converts "13:00:00" or "13:00" → "1:00 PM"
  String _fmt(String raw) {
    try {
      final p = raw.split(':');
      final hour = int.parse(p[0]);
      final min = p[1];
      if (hour == 0) return '12:$min AM';
      if (hour < 12) return '$hour:$min AM';
      if (hour == 12) return '12:$min PM';
      return '${hour - 12}:$min PM';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminThemeWrapper(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Manage Slots'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add_slot',
          onPressed: _openAddSlotMenu,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Slots', style: TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Calendar ──────────────────────────────────
              Container(
                color: Colors.white,
                child: TableCalendar(
                  // Extended to 1 year to match BulkSlotScreen
                  firstDay: DateTime.now().subtract(const Duration(days: 30)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  onDaySelected: _onDaySelected,
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),

              // ── Slot list ─────────────────────────────────
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
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.error!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  ctx.read<BookingProvider>().fetchAdminSlots(
                                    date: _fmtDate(_selectedDay),
                                  ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
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
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No slots for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _openBulkSlotSheet,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Bulk-add slots for this day'),
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
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: provider.adminSlots.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final slot = provider.adminSlots[i];
                          return _SlotTile(
                            slot: slot,
                            fmt: _fmt,
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
        ),
      ),
    );
  }
}

// ── Slot tile ─────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  final SlotModel slot;
  final String Function(String) fmt;
  final VoidCallback onDelete;

  const _SlotTile({
    required this.slot,
    required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isBooked = !slot.isAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBooked
              ? Colors.orange.withOpacity(0.4)
              : Colors.green.withOpacity(0.4),
        ),
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
              '${fmt(slot.startTime)} – ${fmt(slot.endTime)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          if (slot.serviceName != null)
            Text(
              slot.serviceName!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isBooked
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
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
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

// ── Single slot sheet ─────────────────────────────────────────

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
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

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
    final success = await provider.createSlot(
      serviceId: _selectedService!.id,
      date: DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      startTime: _fmtTime(_startTime),
      endTime: _fmtTime(_endTime),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pop(context);
      widget.onCreated();
      SnackbarUtils.showSuccess(context, 'Slot created');
    } else {
      SnackbarUtils.showError(
        context,
        provider.error ?? 'Failed to create slot',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services;
    final dateLabel = DateFormat('EEE, MMM d yyyy').format(widget.selectedDate);
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: _SheetWrapper(
        title: 'Add Single Slot',
        subtitle: dateLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ServiceModel>(
              value: _selectedService,
              hint: const Text('Select Service'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Service',
              ),
              items: services
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedService = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Start Time',
                    time: _startTime,
                    onTap: () => _pickTime(isStart: true),
                    ctx: context,
                  ),
                ),
                Expanded(
                  child: _TimePicker(
                    label: 'End Time',
                    time: _endTime,
                    onTap: () => _pickTime(isStart: false),
                    ctx: context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SubmitButton(
              isLoading: _isLoading,
              label: 'Create Slot',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bulk slot sheet ───────────────────────────────────────────

class _BulkSlotSheet extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onCreated;
  const _BulkSlotSheet({required this.selectedDate, required this.onCreated});
  @override
  State<_BulkSlotSheet> createState() => _BulkSlotSheetState();
}

class _BulkSlotSheetState extends State<_BulkSlotSheet> {
  ServiceModel? _selectedService;
  TimeOfDay _from = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 17, minute: 0);
  int _interval = 30;
  bool _isLoading = false;

  final _intervals = [15, 20, 30, 45, 60, 90, 120];

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:00';

  List<(TimeOfDay, TimeOfDay)> _generateSlots() {
    final slots = <(TimeOfDay, TimeOfDay)>[];
    var current = _from;
    while (true) {
      final totalStart = current.hour * 60 + current.minute;
      final totalEnd = totalStart + _interval;
      if (totalEnd > _to.hour * 60 + _to.minute) break;
      slots.add((
        current,
        TimeOfDay(hour: totalEnd ~/ 60, minute: totalEnd % 60),
      ));
      current = TimeOfDay(hour: totalEnd ~/ 60, minute: totalEnd % 60);
    }
    return slots;
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _from : _to,
    );
    if (picked != null) {
      setState(() => isFrom ? _from = picked : _to = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedService == null) {
      SnackbarUtils.showError(context, 'Please select a service');
      return;
    }
    final preview = _generateSlots();
    if (preview.isEmpty) {
      SnackbarUtils.showError(
        context,
        'No slots to create — check your time range',
      );
      return;
    }
    setState(() => _isLoading = true);
    final provider = context.read<BookingProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    int created = 0, skipped = 0;
    for (final (start, end) in preview) {
      final ok = await provider.createSlot(
        serviceId: _selectedService!.id,
        date: dateStr,
        startTime: _fmtTime(start),
        endTime: _fmtTime(end),
      );
      if (ok)
        created++;
      else
        skipped++;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    final msg =
        '$created slot(s) created'
        '${skipped > 0 ? ', $skipped skipped (already exist)' : ''}.';
    widget.onCreated();
    if (created > 0) {
      SnackbarUtils.showSuccess(context, msg);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services;
    final preview = _generateSlots();
    final dateLabel = DateFormat('EEE, MMM d yyyy').format(widget.selectedDate);
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: _SheetWrapper(
        title: 'Bulk Add Slots',
        subtitle: dateLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<ServiceModel>(
              value: _selectedService,
              hint: const Text('Select Service'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Service',
              ),
              items: services
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedService = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'From',
                    time: _from,
                    onTap: () => _pickTime(isFrom: true),
                    ctx: context,
                  ),
                ),
                Expanded(
                  child: _TimePicker(
                    label: 'To',
                    time: _to,
                    onTap: () => _pickTime(isFrom: false),
                    ctx: context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Slot Duration / Interval',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _intervals.map((min) {
                final selected = _interval == min;
                return ChoiceChip(
                  label: Text('${min}min'),
                  selected: selected,
                  onSelected: (_) => setState(() => _interval = min),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : null,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                preview.isEmpty
                    ? 'No slots in range'
                    : '${preview.length} slot(s) will be created  '
                          '(${_from.format(context)} → ${_to.format(context)}, every ${_interval}min)',
                style: TextStyle(
                  fontSize: 13,
                  color: preview.isEmpty ? AppColors.error : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SubmitButton(
              isLoading: _isLoading,
              label: 'Create ${preview.length} Slot(s)',
              onPressed: preview.isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sheet helpers ──────────────────────────────────────

class _SheetWrapper extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _SheetWrapper({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final BuildContext ctx;
  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 13)),
    subtitle: Text(
      time.format(ctx),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
    leading: const Icon(Icons.access_time, color: AppColors.primary),
    onTap: onTap,
  );
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;
  const _SubmitButton({
    required this.isLoading,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
    ),
  );
}
