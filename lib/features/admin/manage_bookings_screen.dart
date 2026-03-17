// lib/features/admin/manage_bookings_screen.dart
// Admin view of all customer bookings.
// Supports filtering by status via filter chips.
// Admin can update any booking's status via a bottom sheet.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:slotwise/widgets/admin_theme_wrapper.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../core/utils/snackbar_utils.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  String _selectedFilter = 'all';
  bool   _fetched        = false; // ✅ guard flag

  final List<String> _filters = [
    'all', 'pending', 'confirmed', 'completed', 'cancelled',
  ];

  // ✅ FIX: didChangeDependencies instead of initState + Future.microtask
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      _loadBookings();
    }
  }

  void _loadBookings() {
    context.read<AdminProvider>().fetchAllBookings(
          status: _selectedFilter == 'all' ? null : _selectedFilter,
        );
  }

  void _openStatusSheet(AdminBooking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusUpdateSheet(
        booking: booking,
        onStatusSelected: (newStatus) async {
          Navigator.pop(context);
          final success = await context
              .read<AdminProvider>()
              .updateBookingStatus(booking.id, newStatus);
          if (mounted) {
            success
                ? SnackbarUtils.showSuccess(context, 'Status updated to $newStatus')
                : SnackbarUtils.showError(context, 'Failed to update status');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminThemeWrapper(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('All Bookings'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // ── Filter Chips ───────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final isActive = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f == 'all' ? 'All' : _capitalize(f)),
                        selected: isActive,
                        onSelected: (_) {
                          setState(() => _selectedFilter = f);
                          _loadBookings();
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isActive ? AppColors.primary : Colors.grey[700],
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
      
            // ── Booking List ── ✅ Builder for correct context scope
            Expanded(
              child: Builder(
                builder: (ctx) {
                  final admin = ctx.watch<AdminProvider>();
      
                  if (admin.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
      
                  if (admin.error != null && admin.bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 8),
                          Text(admin.error!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadBookings,
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
      
                  if (admin.bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('No bookings found',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    );
                  }
      
                  return RefreshIndicator(
                    onRefresh: () async => _loadBookings(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: admin.bookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final booking = admin.bookings[i];
                        return _AdminBookingCard(
                          booking: booking,
                          onTap: () => _openStatusSheet(booking),
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
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Admin Booking Card ────────────────────────────────────────

class _AdminBookingCard extends StatelessWidget {
  final AdminBooking booking;
  final VoidCallback onTap;
  const _AdminBookingCard({required this.booking, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':  return Colors.green;
      case 'pending':    return Colors.orange;
      case 'completed':  return Colors.blue;
      case 'cancelled':  return Colors.red;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color     = _statusColor(booking.status);
    final dateLabel = DateFormat('MMM d, yyyy').format(
        DateTime.tryParse(booking.date) ?? DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(booking.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(booking.serviceName,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$dateLabel · ${booking.startTime} – ${booking.endTime}',
                    style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Text('\$${booking.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(booking.customerEmail,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 6),
            Text('Tap to update status →',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

// ── Status Update Bottom Sheet ────────────────────────────────

class _StatusUpdateSheet extends StatelessWidget {
  final AdminBooking booking;
  final void Function(String) onStatusSelected;
  const _StatusUpdateSheet(
      {required this.booking, required this.onStatusSelected});

  static const _statuses = [
    {'value': 'pending',   'label': 'Pending',   'icon': Icons.hourglass_empty,       'color': Colors.orange},
    {'value': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle_outline,  'color': Colors.green},
    {'value': 'completed', 'label': 'Completed', 'icon': Icons.task_alt,              'color': Colors.blue},
    {'value': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel_outlined,       'color': Colors.red},
  ];

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
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Update Booking Status',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text('Booking #${booking.id} · ${booking.customerName}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 20),
          ..._statuses.map((s) {
            final isCurrent = booking.status == s['value'];
            final color     = s['color'] as Color;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(s['icon'] as IconData, color: color),
              title: Text(s['label'] as String,
                  style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal)),
              trailing: isCurrent
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: isCurrent
                  ? null
                  : () => onStatusSelected(s['value'] as String),
            );
          }),
        ],
      ),
    );
  }
}
