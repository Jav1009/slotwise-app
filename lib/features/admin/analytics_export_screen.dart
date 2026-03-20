// lib/features/admin/analytics_export_screen.dart
// Standalone export screen. Fetches its own data based on the
// selected period so exports are always scoped correctly.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin_theme_wrapper.dart';

class AnalyticsExportScreen extends StatefulWidget {
  const AnalyticsExportScreen({super.key});

  @override
  State<AnalyticsExportScreen> createState() => _AnalyticsExportScreenState();
}

class _AnalyticsExportScreenState extends State<AnalyticsExportScreen> {
  String _selectedPeriod = 'Last 30 Days';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;

  final List<String> _periods = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'This Month',
    'Last Month',
    'This Year',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  void _fetchData() {
    context.read<AdminProvider>().fetchStats(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _updatePeriod(String period) async {
    if (period == 'Custom Range') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 730)),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom Range';
      });
      _fetchData();
      return;
    }

    final now = DateTime.now();
    DateTime start, end;
    switch (period) {
      case 'Today':
        start = end = now;
        break;
      case 'Yesterday':
        start = end = now.subtract(const Duration(days: 1));
        break;
      case 'Last 7 Days':
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case 'Last 30 Days':
        start = now.subtract(const Duration(days: 30));
        end = now;
        break;
      case 'Last 90 Days':
        start = now.subtract(const Duration(days: 90));
        end = now;
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = now;
        break;
      default:
        start = now.subtract(const Duration(days: 30));
        end = now;
    }

    setState(() {
      _selectedPeriod = period;
      _startDate = start;
      _endDate = end;
    });
    _fetchData();
  }

  String _fmtDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  String _fmtCurrency(double v) =>
      NumberFormat.currency(locale: 'en_US', symbol: r'$').format(v);

  Future<void> _exportCsv(AdminStats stats) async {
    setState(() => _isExporting = true);
    try {
      // Build clean, properly quoted CSV
      final rows = <List<String>>[
        ['SlotWise Analytics Report'],
        ['Period', _selectedPeriod],
        ['Range', '${_fmtDate(_startDate)} to ${_fmtDate(_endDate)}'],
        [],
        ['OVERVIEW'],
        ['Metric', 'Value'],
        ['Total Bookings', '${stats.totalBookings}'],
        ["Today's Bookings", '${stats.todayBookings}'],
        ['Pending Bookings', '${stats.pendingBookings}'],
        ['Confirmed/Completed Bookings', '${stats.confirmedBookings}'],
        ['Cancelled Bookings', '${stats.cancelledBookings}'],
        [],
        ['REVENUE'],
        ['Metric', 'Value'],
        ['Confirmed Revenue', _fmtCurrency(stats.confirmedRevenue)],
        ['Pending Revenue (actual prices)', _fmtCurrency(stats.pendingRevenue)],
        [
          'Projected Revenue (confirmed + pending)',
          _fmtCurrency(stats.projectedRevenue),
        ],
        [
          'Avg Revenue per Confirmed Booking',
          _fmtCurrency(stats.avgRevenuePerBooking),
        ],
        ['Confirmed Bookings', '${stats.confirmedBookings}'],
        [],
        ['TOP SERVICES'],
        ['Rank', 'Service', 'Bookings'],
        ...stats.popularServices.asMap().entries.map(
          (e) => [
            '${e.key + 1}',
            e.value['name'] as String? ?? '',
            '${e.value['booking_count'] ?? 0}',
          ],
        ),
      ];

      // Properly escape fields that contain commas or quotes
      String escapeField(String f) {
        if (f.contains(',') || f.contains('"') || f.contains('\n')) {
          return '"${f.replaceAll('"', '""')}"';
        }
        return f;
      }

      final csv = rows.map((row) => row.map(escapeField).join(',')).join('\n');

      final dir = await getTemporaryDirectory();
      final filename =
          'slotwise_${_selectedPeriod.replaceAll(' ', '_').toLowerCase()}_'
          '${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'SlotWise Analytics — $_selectedPeriod');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminThemeWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Export Report'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Consumer<AdminProvider>(
            builder: (ctx, admin, _) {
              final stats = admin.stats;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Period selector ──────────────────────
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Export Period',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedPeriod,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            items: _periods
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _updatePeriod(v);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_fmtDate(_startDate)} – ${_fmtDate(_endDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Data preview ─────────────────────────
                    const _SectionTitle('Data Preview'),
                    const SizedBox(height: 12),

                    if (admin.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (admin.error != null)
                      _card(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              admin.error!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _fetchData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (stats != null) ...[
                      // Overview
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle('Bookings'),
                            const SizedBox(height: 10),
                            _previewRow(
                              'Total Bookings',
                              '${stats.totalBookings}',
                            ),
                            _previewRow('Pending', '${stats.pendingBookings}'),
                            _previewRow(
                              'Confirmed/Completed',
                              '${stats.confirmedBookings}',
                            ),
                            _previewRow(
                              'Cancelled',
                              '${stats.cancelledBookings}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Revenue
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle('Revenue'),
                            const SizedBox(height: 10),
                            _previewRow(
                              'Confirmed Revenue',
                              _fmtCurrency(stats.confirmedRevenue),
                              valueColor: const Color(0xFF06D6A0),
                            ),
                            _previewRow(
                              'Pending Revenue',
                              _fmtCurrency(stats.pendingRevenue),
                              valueColor: const Color(0xFFFFB347),
                            ),
                            _previewRow(
                              'Projected (Conf. + Pend.)',
                              _fmtCurrency(stats.projectedRevenue),
                              valueColor: const Color(0xFF6C63FF),
                            ),
                            _previewRow(
                              'Avg / Confirmed Booking',
                              _fmtCurrency(stats.avgRevenuePerBooking),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Top services
                      if (stats.popularServices.isNotEmpty)
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle('Top Services'),
                              const SizedBox(height: 10),
                              ...stats.popularServices.asMap().entries.map(
                                (e) => _previewRow(
                                  '${e.key + 1}. ${e.value['name']}',
                                  '${e.value['booking_count']} booking'
                                      '${(e.value['booking_count'] as int? ?? 0) == 1 ? '' : 's'}',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],

                    const SizedBox(height: 24),

                    // ── Export button ────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (stats == null || _isExporting)
                            ? null
                            : () => _exportCsv(stats),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.share_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isExporting ? 'Preparing export…' : 'Export as CSV',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Opens your device\'s share sheet.\n'
                        'Save to Files, email, or open in Sheets/Excel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _previewRow(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1A1A2E),
    ),
  );
}
