// lib/features/admin/bulk_slots_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/admin_theme_wrapper.dart';

class BulkSlotScreen extends StatefulWidget {
  const BulkSlotScreen({super.key});

  @override
  State<BulkSlotScreen> createState() => _BulkSlotScreenState();
}

class _BulkSlotScreenState extends State<BulkSlotScreen> {
  // ── State ──────────────────────────────────────────────────
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd   = DateTime.now().add(const Duration(days: 7));

  final Set<int> _selectedDays    = {1, 2, 3, 4, 5}; // Mon–Fri
  TimeOfDay      _startTime       = const TimeOfDay(hour: 9,  minute: 0);
  TimeOfDay      _endTime         = const TimeOfDay(hour: 17, minute: 0);
  int            _intervalMinutes = 30;

  int?    _selectedServiceId;
  String? _selectedServiceName;
  bool    _isLoading = false;

  final _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _dateFmt   = DateFormat('MMM d, yyyy');
  final _isoFmt    = DateFormat('yyyy-MM-dd');

  // ── Date pickers ───────────────────────────────────────────

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _rangeStart : _rangeEnd;
    final first   = isStart ? DateTime.now() : _rangeStart;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        _rangeStart = picked;
        // If new start is pushed past end, move end forward too
        if (_rangeEnd.isBefore(_rangeStart)) _rangeEnd = _rangeStart;
      } else {
        _rangeEnd = picked;
      }
    });
  }

  // ── Time pickers ───────────────────────────────────────────

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() =>
          isStart ? _startTime = picked : _endTime = picked);
    }
  }

  // ── Slot generation ────────────────────────────────────────

  List<Map<String, dynamic>> _generateSlots() {
    final slots   = <Map<String, dynamic>>[];
    var   current = _rangeStart;

    while (!current.isAfter(_rangeEnd)) {
      if (_selectedDays.contains(current.weekday)) {
        var slotTime = DateTime(
          current.year, current.month, current.day,
          _startTime.hour, _startTime.minute,
        );
        final endDt = DateTime(
          current.year, current.month, current.day,
          _endTime.hour, _endTime.minute,
        );
        while (slotTime.isBefore(endDt)) {
          final slotEnd =
              slotTime.add(Duration(minutes: _intervalMinutes));
          if (!slotEnd.isAfter(endDt)) {
            slots.add({
              'service_id': _selectedServiceId,
              'date':       _isoFmt.format(current),
              'start_time': _timeStr(slotTime),
              'end_time':   _timeStr(slotEnd),
              'is_available': true,
            });
          }
          slotTime = slotEnd;
        }
      }
      current = current.add(const Duration(days: 1));
    }
    return slots;
  }

  String _timeStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  // ── Submit ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one day')),
      );
      return;
    }

    final slots = _generateSlots();
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No slots generated — check your time range.')),
      );
      return;
    }

    // Capture context-dependent values before the async gap
    final startLabel = _startTime.format(context);
    final endLabel   = _endTime.format(context);

    final confirmed = await showAdminDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Bulk Create'),
        content: Text(
          'This will create ${slots.length} slots for '
          '"$_selectedServiceName".\n\n'
          'From: ${_isoFmt.format(_rangeStart)}\n'
          'To:   ${_isoFmt.format(_rangeEnd)}\n'
          'Time: $startLabel – $endLabel\n'
          'Every $_intervalMinutes minutes',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AdminProvider>().bulkCreateSlots(slots);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${slots.length} slots created!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final services     = context.watch<ServiceProvider>().services;
    final previewCount = _generateSlots().length;

    return AdminThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bulk Add Slots'),
          centerTitle: true,
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Service picker ────────────────────────────
              _SectionLabel('Service'),
              DropdownButtonFormField<int>(
                initialValue: _selectedServiceId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a service',
                ),
                items: services.map((s) {
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.name),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _selectedServiceId   = v;
                    _selectedServiceName =
                        services.firstWhere((s) => s.id == v).name;
                  });
                },
              ),
              const SizedBox(height: 20),

              // ── Date range — calendar (two-tap) ──────────
              _SectionLabel('Date Range'),
              Card(
                child: Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now()
                      .add(const Duration(days: 365)),
                  focusedDay: _rangeStart,
                  rangeStartDay: _rangeStart,
                  rangeEndDay: _rangeEnd,
                  calendarFormat: CalendarFormat.month,
                  rangeSelectionMode:
                      RangeSelectionMode.enforced,
                  onRangeSelected: (start, end, focused) {
                    setState(() {
                      if (start != null) _rangeStart = start;
                      if (end   != null) _rangeEnd   = end;
                    });
                  },
                  headerStyle: const HeaderStyle(
                      formatButtonVisible: false),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Date range — individual tap pickers ───────
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label:   'Start Date',
                      display: _dateFmt.format(_rangeStart),
                      onTap:   () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTile(
                      label:   'End Date',
                      display: _dateFmt.format(_rangeEnd),
                      onTap:   () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Days of week ──────────────────────────────
              _SectionLabel('Repeat On'),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final day      = i + 1;
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(_dayLabels[i]),
                    selected: selected,
                    onSelected: (val) {
                      setState(() => val
                          ? _selectedDays.add(day)
                          : _selectedDays.remove(day));
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),

              // ── Time range ────────────────────────────────
              _SectionLabel('Time Range'),
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Start',
                      time:  _startTime.format(context),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
                      label: 'End',
                      time:  _endTime.format(context),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Slot duration ─────────────────────────────
              _SectionLabel('Slot Duration (minutes)'),
              Wrap(
                spacing: 8,
                children: [15, 30, 45, 60, 90].map((mins) {
                  return ChoiceChip(
                    label: Text('$mins min'),
                    selected: _intervalMinutes == mins,
                    onSelected: (_) =>
                        setState(() => _intervalMinutes = mins),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Preview count ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$previewCount slots will be created',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline),
                  label: Text(
                      _isLoading ? 'Creating...' : 'Create All Slots'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );
}

class _DateTile extends StatelessWidget {
  final String     label;
  final String     display;
  final VoidCallback onTap;
  const _DateTile({
    required this.label,
    required this.display,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .outline),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    display,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String     label;
  final String     time;
  final VoidCallback onTap;
  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .outline),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                          fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}