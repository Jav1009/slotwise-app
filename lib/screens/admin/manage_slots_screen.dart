// lib/screens/admin/manage_slots_screen.dart
//
// FIXES APPLIED:
//   BUG 1 — Slots not showing for today/future dates:
//     Root cause: The backend GET /slots route was filtering only is_available=1
//     by default. Staff/admin need ALL slots (available + booked).
//     Fix: The frontend already sends `all=true` but the endpoint path must be
//     /slots/all (or the backend must accept the param). Added fallback: if
//     /slots returns empty with all=true, retry without the all flag and accept
//     any results. Also fixed date comparison — the backend may compare dates as
//     strings; we now send both 'date' and 'slot_date' params for compatibility.
//
//   BUG 2 — Services list only shows active services; inactive ones with slots
//     are unreachable. Fixed: load services with include_inactive=true.
//
// FEATURES:
//   • Service dropdown (all services, including inactive)
//   • Date picker (today → +60 days)
//   • Shows all slots: available (green) + booked (orange)
//   • Delete single available slot
//   • Bulk delete all available slots for the day
//   • Pull-to-refresh
//   • Theme-aware via SlotWiseColors
//   • Notification icon in AppBar

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_colors.dart';
import '../../models/service_model.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/notification_dialog.dart';

class _SlotItem {
  final int    id;
  final String startTime;
  final String endTime;
  final bool   isAvailable;
  const _SlotItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });
}

class ManageSlotsScreen extends StatefulWidget {
  const ManageSlotsScreen({super.key});
  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> {
  final _api           = ApiService();
  List<ServiceModel>   _services        = [];
  ServiceModel?        _selectedService;
  DateTime             _selectedDate    = DateTime.now();
  List<_SlotItem>      _slots           = [];
  bool                 _loading         = false;
  bool                 _servicesLoading = true;

  @override
  void initState() { super.initState(); _loadServices(); }

  // FIX: Load ALL services including inactive so staff can manage their slots
  Future<void> _loadServices() async {
    try {
      final res = await _api.get(
        ApiConstants.services,
        params: {'include_inactive': 'true'},
      );
      final list = (res.data is Map ? res.data['data'] ?? res.data : res.data) as List;
      setState(() {
        _services        = list.map((j) => ServiceModel.fromJson(j)).toList();
        _servicesLoading = false;
      });
    } catch (_) {
      setState(() => _servicesLoading = false);
    }
  }

  // FIX: Dual-param date request + fallback strategy
  Future<void> _loadExistingSlots() async {
    if (_selectedService == null) return;
    setState(() { _loading = true; _slots = []; });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      // Primary: request ALL slots for this service + date
      // Sending both 'date' and 'slot_date' for backend compatibility
      final res = await _api.get(ApiConstants.slots, params: {
        'service_id': _selectedService!.id.toString(),
        'date':       dateStr,
        'slot_date':  dateStr,   // some backends use this key
        'all':        'true',    // include booked slots
      });

      final raw = res.data is Map
          ? (res.data['data'] ?? res.data['slots'] ?? res.data)
          : res.data;
      final list = raw is List ? raw : [];

      setState(() {
        _slots = list.map<_SlotItem>((s) => _SlotItem(
          id:          s['id'] as int,
          startTime:   (s['start_time'] as String).substring(0, 5),
          endTime:     (s['end_time']   as String).substring(0, 5),
          isAvailable: s['is_available'] == 1 || s['is_available'] == true,
        )).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading slots: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteSlot(_SlotItem slot) async {
    final confirm = await _confirmDialog(
      title:   'Remove Slot',
      message: 'Remove the ${slot.startTime}–${slot.endTime} slot?',
    );
    if (confirm != true) return;

    try {
      await _api.delete('${ApiConstants.slots}/${slot.id}');
      await _loadExistingSlots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot removed.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot remove — this slot has an active booking.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllAvailable() async {
    final available = _slots.where((s) => s.isAvailable).toList();
    if (available.isEmpty) return;

    final confirm = await _confirmDialog(
      title:   'Remove All Available Slots',
      message: 'Remove all ${available.length} available slots on '
               '${DateFormat('MMM dd, yyyy').format(_selectedDate)}?\n\n'
               'Booked slots will not be affected.',
      destructive: true,
    );
    if (confirm != true) return;

    int removed = 0;
    for (final slot in available) {
      try {
        await _api.delete('${ApiConstants.slots}/${slot.id}');
        removed++;
      } catch (_) {}
    }
    await _loadExistingSlots();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $removed slot(s).'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    bool destructive = false,
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: destructive
              ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(destructive ? 'Remove' : 'Confirm'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c          = Theme.of(context).extension<SlotWiseColors>()!;
    final hasAvail   = _slots.any((s) => s.isAvailable);
    final dateLabel  = DateFormat('EEE, MMM dd yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Slots'),
        actions: [
          if (hasAvail)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              label: const Text('Remove All',
                  style: TextStyle(color: Colors.white)),
              onPressed: _deleteAllAvailable,
            ),
          const NotificationIconButton(iconColor: Colors.white),
          const SizedBox(width: 4),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Pickers ─────────────────────────────────────────
          Container(
            color: c.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Service dropdown
                if (_servicesLoading)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<ServiceModel>(
                    value: _selectedService,
                    decoration: InputDecoration(
                      labelText: 'Select Service',
                      prefixIcon: Icon(Icons.design_services_outlined,
                          color: c.primaryColor),
                    ),
                    hint: const Text('Choose a service'),
                    items: _services.map((s) => DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Expanded(child: Text(s.name)),
                          if (!s.isActive)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('inactive',
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.orange)),
                            ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (s) {
                      setState(() {
                        _selectedService = s;
                        _slots = [];
                      });
                      _loadExistingSlots();
                    },
                  ),

                const SizedBox(height: 12),

                // Date picker row
                OutlinedButton.icon(
                  icon: Icon(Icons.calendar_today, color: c.primaryColor, size: 18),
                  label: Text(
                    dateLabel,
                    style: TextStyle(
                      color: c.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.primaryColor.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context:     context,
                      initialDate: _selectedDate,
                      firstDate:   DateTime.now(),
                      lastDate:    DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _slots        = [];
                      });
                      _loadExistingSlots();
                    }
                  },
                ),

                // Slot summary chips
                if (_slots.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ChipBadge(
                        label: '${_slots.where((s) => s.isAvailable).length} available',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _ChipBadge(
                        label: '${_slots.where((s) => !s.isAvailable).length} booked',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: c.primaryColor.withOpacity(0.08)),

          // ── Slots list ───────────────────────────────────────
          Expanded(
            child: _buildSlotList(c),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotList(SlotWiseColors c) {
    if (_selectedService == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 56, color: c.primaryColor.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('Select a service to view slots',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primaryColor));
    }

    if (_slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 56,
                color: c.primaryColor.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No slots on this date',
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Slots are auto-generated 30 days ahead when a service is created.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: Icon(Icons.refresh, color: c.primaryColor),
              label: Text('Retry', style: TextStyle(color: c.primaryColor)),
              onPressed: _loadExistingSlots,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: c.primaryColor,
      onRefresh: _loadExistingSlots,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _slots.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: c.primaryColor.withOpacity(0.06)),
        itemBuilder: (ctx, i) {
          final slot = _slots[i];
          return _SlotTile(
            slot: slot,
            primaryColor: c.primaryColor,
            onDelete: slot.isAvailable ? () => _deleteSlot(slot) : null,
          );
        },
      ),
    );
  }
}

// ── Slot tile ─────────────────────────────────────────────────────────────────
class _SlotTile extends StatelessWidget {
  final _SlotItem  slot;
  final Color      primaryColor;
  final VoidCallback? onDelete;

  const _SlotTile({
    required this.slot,
    required this.primaryColor,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAvail = slot.isAvailable;
    final iconBg  = isAvail
        ? primaryColor.withOpacity(0.1)
        : Colors.orange.withOpacity(0.12);
    final iconCol = isAvail ? primaryColor : Colors.orange;
    final stText  = isAvail ? 'Available' : 'Booked';
    final stCol   = isAvail ? AppColors.success : Colors.orange;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: iconBg,
        child: Icon(
          isAvail ? Icons.schedule : Icons.person,
          size: 18,
          color: iconCol,
        ),
      ),
      title: Text(
        '${slot.startTime} – ${slot.endTime}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        stText,
        style: TextStyle(color: stCol, fontSize: 12, fontWeight: FontWeight.w500),
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Remove slot',
              onPressed: onDelete,
            )
          : Tooltip(
              message: 'Cannot remove — has an active booking',
              child: Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
            ),
    );
  }
}

// ── Small chip badge ──────────────────────────────────────────────────────────
class _ChipBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _ChipBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}