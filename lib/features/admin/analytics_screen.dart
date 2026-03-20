// lib/features/admin/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin_theme_wrapper.dart';
import 'analytics_export_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime _startDate     = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate       = DateTime.now();
  String   _selectedPeriod = 'Last 30 Days';
  bool     _fetched       = false;

  final List<String> _periods = [
    'Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days',
    'Last 90 Days', 'This Month', 'Last Month', 'This Year', 'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      _fetchWithRange();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchWithRange() {
    context.read<AdminProvider>().fetchStats(
      startDate: _startDate,
      endDate:   _endDate,
    );
  }

  Future<void> _updatePeriod(String period) async {
    if (period == 'Custom Range') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 730)),
        lastDate:  DateTime.now(),
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
      if (picked == null || !mounted) return;
      setState(() {
        _startDate      = picked.start;
        _endDate        = picked.end;
        _selectedPeriod = 'Custom Range';
      });
      _fetchWithRange();
      return;
    }

    final now = DateTime.now();
    late DateTime start, end;
    switch (period) {
      case 'Today':
        start = end = now;
      case 'Yesterday':
        start = end = now.subtract(const Duration(days: 1));
      case 'Last 7 Days':
        start = now.subtract(const Duration(days: 7)); end = now;
      case 'Last 30 Days':
        start = now.subtract(const Duration(days: 30)); end = now;
      case 'Last 90 Days':
        start = now.subtract(const Duration(days: 90)); end = now;
      case 'This Month':
        start = DateTime(now.year, now.month, 1); end = now;
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end   = DateTime(now.year, now.month, 0);
      case 'This Year':
        start = DateTime(now.year, 1, 1); end = now;
      default:
        start = now.subtract(const Duration(days: 30)); end = now;
    }

    setState(() {
      _selectedPeriod = period;
      _startDate      = start;
      _endDate        = end;
    });
    _fetchWithRange();
  }

  String _fmtDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

  String _fmtCurrency(double v) =>
      NumberFormat.currency(locale: 'en_US', symbol: r'$').format(v);

  @override
  Widget build(BuildContext context) {
    return AdminThemeWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Analytics'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Revenue'),
              Tab(text: 'Services'),
              Tab(text: 'Reports'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchWithRange,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: SafeArea(
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) {
              if (admin.isLoading && admin.stats == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (admin.error != null && admin.stats == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(admin.error!,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchWithRange,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final stats = admin.stats;
              return TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    stats:           stats,
                    selectedPeriod:  _selectedPeriod,
                    periods:         _periods,
                    startDate:       _startDate,
                    endDate:         _endDate,
                    onPeriodChanged: _updatePeriod,
                    fmtDate:         _fmtDate,
                    fmtCurrency:     _fmtCurrency,
                  ),
                  _RevenueTab(stats: stats, fmtCurrency: _fmtCurrency),
                  _ServicesTab(stats: stats),
                  _ReportsTab(stats: stats),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — Overview
// ══════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final AdminStats? stats;
  final String selectedPeriod;
  final List<String> periods;
  final DateTime startDate, endDate;
  final void Function(String) onPeriodChanged;
  final String Function(DateTime) fmtDate;
  final String Function(double) fmtCurrency;

  const _OverviewTab({
    required this.stats,
    required this.selectedPeriod,
    required this.periods,
    required this.startDate,
    required this.endDate,
    required this.onPeriodChanged,
    required this.fmtDate,
    required this.fmtCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().fetchStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodCard(
              selectedPeriod: selectedPeriod,
              periods:        periods,
              startDate:      startDate,
              endDate:        endDate,
              onChanged:      onPeriodChanged,
              fmtDate:        fmtDate,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Bookings Summary'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _MetricCard(
                  label: "Today's Bookings",
                  value: '${stats?.todayBookings ?? 0}',
                  icon: Icons.today_rounded,
                  color: const Color(0xFF6C63FF),
                ),
                _MetricCard(
                  label: 'Pending',
                  value: '${stats?.pendingBookings ?? 0}',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFFFB347),
                ),
                _MetricCard(
                  label: 'Confirmed',
                  value: '${stats?.confirmedBookings ?? 0}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.confirmed,
                ),
                _MetricCard(
                  label: 'Cancelled',
                  value: '${stats?.cancelledBookings ?? 0}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.cancelled,
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _SectionTitle('Status Distribution'),
            const SizedBox(height: 12),
            _StatusPieCard(stats: stats),
          ],
        ),
      ),
    );
  }
}

class _StatusPieCard extends StatelessWidget {
  final AdminStats? stats;
  const _StatusPieCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final total     = (stats?.totalBookings     ?? 0).toDouble();
    final pending   = (stats?.pendingBookings   ?? 0).toDouble();
    final confirmed = (stats?.confirmedBookings ?? 0).toDouble();
    final cancelled = (stats?.cancelledBookings ?? 0).toDouble();

    if (total == 0) {
      return const _EmptyCard('No booking data for this period');
    }

    return _Card(
      child: Row(
        children: [
          SizedBox(
            width: 160, height: 160,
            child: PieChart(PieChartData(
              sections: [
                if (pending > 0)
                  PieChartSectionData(
                    value: pending,
                    title: '${((pending / total) * 100).toStringAsFixed(0)}%',
                    color: AppColors.pending,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                if (confirmed > 0)
                  PieChartSectionData(
                    value: confirmed,
                    title: '${((confirmed / total) * 100).toStringAsFixed(0)}%',
                    color: AppColors.confirmed,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                if (cancelled > 0)
                  PieChartSectionData(
                    value: cancelled,
                    title: '${((cancelled / total) * 100).toStringAsFixed(0)}%',
                    color: AppColors.cancelled,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 28,
            )),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem('Pending',   AppColors.pending,   stats?.pendingBookings   ?? 0),
              const SizedBox(height: 10),
              _LegendItem('Confirmed', AppColors.confirmed, stats?.confirmedBookings ?? 0),
              const SizedBox(height: 10),
              _LegendItem('Cancelled', AppColors.cancelled, stats?.cancelledBookings ?? 0),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 — Revenue
// ══════════════════════════════════════════════════════════════

class _RevenueTab extends StatelessWidget {
  final AdminStats? stats;
  final String Function(double) fmtCurrency;
  const _RevenueTab({required this.stats, required this.fmtCurrency});

  @override
  Widget build(BuildContext context) {
    final confirmed     = stats?.confirmedRevenue    ?? 0.0;
    final pending       = stats?.pendingRevenue      ?? 0.0;
    final projected     = stats?.projectedRevenue    ?? 0.0;
    final avgPerBooking = stats?.avgRevenuePerBooking ?? 0.0;

    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().fetchStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Revenue Summary'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _MetricCard(
                  label: 'Confirmed Revenue',
                  value: fmtCurrency(confirmed),
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF06D6A0),
                ),
                _MetricCard(
                  label: 'Pending Revenue',
                  value: fmtCurrency(pending),
                  icon: Icons.pending_rounded,
                  color: const Color(0xFFFFB347),
                ),
                _MetricCard(
                  label: 'Avg / Confirmed Booking',
                  value: fmtCurrency(avgPerBooking),
                  icon: Icons.show_chart_rounded,
                  color: AppColors.primary,
                ),
                _MetricCard(
                  label: 'Projected Revenue',
                  value: fmtCurrency(projected),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF6C63FF),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Revenue Breakdown'),
            const SizedBox(height: 12),
            _RevenueDetailCard(stats: stats, fmtCurrency: fmtCurrency),
            const SizedBox(height: 24),
            const _SectionTitle('Confirmed vs Pending Revenue'),
            const SizedBox(height: 12),
            _RevenueBarChart(
              confirmed:   confirmed,
              pending:     pending,
              fmtCurrency: fmtCurrency,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueDetailCard extends StatelessWidget {
  final AdminStats? stats;
  final String Function(double) fmtCurrency;
  const _RevenueDetailCard({required this.stats, required this.fmtCurrency});

  @override
  Widget build(BuildContext context) {
    return _Card(
      shadow: const Color(0xFF06D6A0),
      child: Column(
        children: [
          _RevRow('Confirmed Revenue',
              fmtCurrency(stats?.confirmedRevenue ?? 0),
              const Color(0xFF06D6A0), large: true),
          const Divider(height: 24),
          _RevRow('Pending Revenue',
              fmtCurrency(stats?.pendingRevenue ?? 0),
              const Color(0xFFFFB347)),
          const SizedBox(height: 12),
          _RevRow('Projected (Confirmed + Pending)',
              fmtCurrency(stats?.projectedRevenue ?? 0),
              const Color(0xFF6C63FF)),
          const SizedBox(height: 12),
          _RevRow('Avg per Confirmed Booking',
              fmtCurrency(stats?.avgRevenuePerBooking ?? 0),
              AppColors.primary),
          const SizedBox(height: 12),
          _RevRow('Confirmed Bookings Contributing',
              '${stats?.confirmedBookings ?? 0}',
              AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _RevRow extends StatelessWidget {
  final String label, value;
  final Color  color;
  final bool   large;
  const _RevRow(this.label, this.value, this.color, {this.large = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(label,
            style: TextStyle(
                fontSize: large ? 14 : 13, color: Colors.grey[600])),
      ),
      Text(value,
          style: TextStyle(
              fontSize: large ? 20 : 15,
              fontWeight: FontWeight.bold,
              color: color)),
    ],
  );
}

// Two bars only: Confirmed and Pending.
// Projected is a derived total shown in the breakdown card above,
// not a separate visual category.
class _RevenueBarChart extends StatelessWidget {
  final double confirmed, pending;
  final String Function(double) fmtCurrency;
  const _RevenueBarChart({
    required this.confirmed,
    required this.pending,
    required this.fmtCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final maxY =
        (confirmed > pending ? confirmed : pending) * 1.2;

    return _Card(
      shadow: const Color(0xFF06D6A0),
      child: SizedBox(
        height: 220,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY > 0 ? maxY : 1000,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                fmtCurrency(rod.toY),
                const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  const labels = ['Confirmed', 'Pending'];
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[i],
                        style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
            leftTitles:  const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          barGroups: [
            _bar(0, confirmed, AppColors.confirmed),
            _bar(1, pending,   const Color(0xFFFFB347)),
          ],
        )),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) =>
      BarChartGroupData(x: x, barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 48,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ]);
}

// ══════════════════════════════════════════════════════════════
// TAB 3 — Services
// ══════════════════════════════════════════════════════════════

class _ServicesTab extends StatelessWidget {
  final AdminStats? stats;
  const _ServicesTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final services = stats?.popularServices ?? [];
    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().fetchStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (services.isEmpty)
              const _EmptyCard('No service data for this period')
            else ...[
              const _SectionTitle('Booking Count by Service'),
              const SizedBox(height: 12),
              _ServicesBarChart(services: services),
              const SizedBox(height: 28),
              const _SectionTitle('Top Services'),
              const SizedBox(height: 12),
              _PopularServicesCard(services: services),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServicesBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  const _ServicesBarChart({required this.services});

  @override
  Widget build(BuildContext context) {
    final counts = services
        .map((s) => (s['booking_count'] as int? ?? 0).toDouble())
        .toList();
    final maxY = counts.isEmpty
        ? 10.0
        : counts.reduce((a, b) => a > b ? a : b) * 1.2;

    const colors = [
      AppColors.primary,
      Color(0xFF6C63FF),
      Color(0xFF00B4D8),
      Color(0xFFFFB347),
      Color(0xFF06D6A0),
    ];

    return _Card(
      child: SizedBox(
        height: 220,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY > 0 ? maxY : 10,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final name =
                    services[group.x]['name'] as String? ?? '';
                return BarTooltipItem(
                  '$name\n${rod.toY.toInt()} bookings',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= services.length) {
                    return const Text('');
                  }
                  final name =
                      services[i]['name'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles:  const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          barGroups: services.asMap().entries.map((e) {
            final count =
                (e.value['booking_count'] as int? ?? 0).toDouble();
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: count,
                color: colors[e.key % colors.length],
                width: 22,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ]);
          }).toList(),
        )),
      ),
    );
  }
}

class _PopularServicesCard extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  const _PopularServicesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        (services.first['booking_count'] as int? ?? 1).clamp(1, 99999);

    return _Card(
      shadow: AppColors.primary,
      child: Column(
        children: services.asMap().entries.map((e) {
          final rank  = e.key + 1;
          final name  = e.value['name'] as String? ?? '—';
          final count = e.value['booking_count'] as int? ?? 0;
          final bar   = maxCount > 0 ? count / maxCount : 0.0;
          final isTop = rank == 1;

          return Padding(
            padding: EdgeInsets.only(
                bottom: e.key < services.length - 1 ? 20 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isTop
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$rank',
                            style: TextStyle(
                              color: isTop
                                  ? Colors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                    Text('$count booking${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: bar.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        AppColors.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isTop
                          ? AppColors.primary
                          : AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 4 — Reports
// ══════════════════════════════════════════════════════════════

class _ReportsTab extends StatelessWidget {
  final AdminStats? stats;
  const _ReportsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Export & Reports'),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download_rounded,
                  color: Colors.green, size: 22),
            ),
            title: const Text('Export Report',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
              'Choose a date range and export as CSV',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AnalyticsExportScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E)));
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? shadow;
  const _Card({required this.child, this.shadow});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (shadow ?? Colors.black).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard(this.message);
  @override
  Widget build(BuildContext context) => _Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
          ),
        ),
      );
}

class _PeriodCard extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periods;
  final DateTime startDate, endDate;
  final void Function(String) onChanged;
  final String Function(DateTime) fmtDate;

  const _PeriodCard({
    required this.selectedPeriod,
    required this.periods,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date Range',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedPeriod,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                isDense: true,
              ),
              items: periods
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${fmtDate(startDate)} – ${fmtDate(endDate)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      );
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _LegendItem(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label: $count',
              style: const TextStyle(fontSize: 13)),
        ],
      );
}