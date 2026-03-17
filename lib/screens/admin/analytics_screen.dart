import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Last 30 Days';
  bool _isLoading = false;
  Map<String, dynamic>? _analyticsData;
  List<Map<String, dynamic>> _bookingTrends = [];
  Map<String, dynamic>? _revenueData;
  List<Map<String, dynamic>> _popularServices = [];

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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      
      await Future.wait([
        bookingProvider.fetchDashboardStats(),
        bookingProvider.fetchAnalytics(
          Formatters.formatApiDate(_startDate),
          Formatters.formatApiDate(_endDate),
        ),
        serviceProvider.fetchServiceStats(),
        _loadPopularServices(),
      ]);

      setState(() {
        _analyticsData = bookingProvider.dashboardStats;
        _bookingTrends = bookingProvider.analytics;
        _revenueData = _calculateRevenue(bookingProvider.allBookings);
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load analytics: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPopularServices() async {
    // This would come from a real API endpoint
    // For now, using mock data
    setState(() {
      _popularServices = [
        {'name': 'Haircut', 'bookings': 45, 'revenue': 1125.00, 'growth': 12.5},
        {'name': 'Beard Trim', 'bookings': 32, 'revenue': 480.00, 'growth': 8.3},
        {'name': 'Full Service', 'bookings': 28, 'revenue': 980.00, 'growth': 15.2},
        {'name': 'Hair Styling', 'bookings': 21, 'revenue': 630.00, 'growth': -2.1},
        {'name': 'Hair Coloring', 'bookings': 15, 'revenue': 750.00, 'growth': 25.0},
      ];
    });
  }

  Map<String, dynamic> _calculateRevenue(List<Booking> bookings) {
    double total = 0;
    double pending = 0;
    double completed = 0;
    
    for (var booking in bookings) {
      total += booking.servicePrice;
      if (booking.isCompleted) {
        completed += booking.servicePrice;
      } else if (booking.isPending || booking.isConfirmed) {
        pending += booking.servicePrice;
      }
    }
    
    return {
      'total': total,
      'pending': pending,
      'completed': completed,
      'projected': total * 1.2, // 20% growth projection
    };
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom Range';
      });
      _loadAnalytics();
    }
  }

  void _updatePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      
      switch (period) {
        case 'Today':
          _startDate = now;
          _endDate = now;
          break;
        case 'Yesterday':
          _startDate = now.subtract(const Duration(days: 1));
          _endDate = now.subtract(const Duration(days: 1));
          break;
        case 'Last 7 Days':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'Last 30 Days':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
        case 'Last 90 Days':
          _startDate = now.subtract(const Duration(days: 90));
          _endDate = now;
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
        case 'Custom Range':
          _showDateRangePicker();
          return;
      }
      
      _loadAnalytics();
    });
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Revenue'),
            Tab(text: 'Services'),
            Tab(text: 'Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading analytics...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRevenueTab(),
                _buildServicesTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Period',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: _periods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updatePeriod(value);
                      }
                    },
                  ),
                  if (_selectedPeriod == 'Custom Range') ...[
                    const SizedBox(height: 12),
                    Text(
                      '${Formatters.formatDate(_startDate)} - ${Formatters.formatDate(_endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // KPI Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildKPICard(
                'Total Bookings',
                _analyticsData?['total_bookings']?.toString() ?? '0',
                Icons.event,
                Colors.blue,
                '+12.5%',
              ),
              _buildKPICard(
                'Revenue',
                _formatCurrency(_revenueData?['total'] ?? 0),
                Icons.attach_money,
                Colors.green,
                '+8.3%',
              ),
              _buildKPICard(
                'Avg. Daily',
                _calculateAverageDaily().toString(),
                Icons.trending_up,
                Colors.orange,
                '+5.2%',
              ),
              _buildKPICard(
                'Conversion Rate',
                '78%',
                Icons.percent,
                Colors.purple,
                '+3.1%',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Booking Trends Chart
          const Text(
            'Booking Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 300,
                child: _bookingTrends.isEmpty
                    ? const Center(child: Text('No data available'))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[300],
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.grey[300],
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && 
                                      value.toInt() < _bookingTrends.length) {
                                    final date = DateTime.parse(
                                      _bookingTrends[value.toInt()]['date']
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${date.day}/${date.month}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString());
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _bookingTrends.asMap().entries.map((entry) {
                                return FlSpot(
                                  entry.key.toDouble(),
                                  (entry.value['total'] as num).toDouble(),
                                );
                              }).toList(),
                              isCurved: true,
                              color: Theme.of(context).primaryColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status Breakdown
          Row(
            children: [
              Expanded(
                child: _buildStatusPieChart(),
              ),
              Expanded(
                child: _buildStatusLegend(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue KPI Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildRevenueKPICard(
                'Total Revenue',
                _formatCurrency(_revenueData?['total'] ?? 0),
                Icons.account_balance_wallet,
                Colors.green,
              ),
              _buildRevenueKPICard(
                'Completed',
                _formatCurrency(_revenueData?['completed'] ?? 0),
                Icons.check_circle,
                Colors.blue,
              ),
              _buildRevenueKPICard(
                'Pending',
                _formatCurrency(_revenueData?['pending'] ?? 0),
                Icons.pending,
                Colors.orange,
              ),
              _buildRevenueKPICard(
                'Projected',
                _formatCurrency(_revenueData?['projected'] ?? 0),
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Revenue Chart
          const Text(
            'Revenue Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (_revenueData?['total'] ?? 1000).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            _formatCurrency(rod.toY),
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const titles = ['Completed', 'Pending', 'Projected'];
                            if (value.toInt() >= 0 && value.toInt() < titles.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  titles[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: _revenueData?['completed']?.toDouble() ?? 0,
                            color: Colors.green,
                            width: 30,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: _revenueData?['pending']?.toDouble() ?? 0,
                            color: Colors.orange,
                            width: 30,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: _revenueData?['projected']?.toDouble() ?? 0,
                            color: Colors.purple,
                            width: 30,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _popularServices.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              const Text(
                'Service Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Service ranking chart
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _popularServices.map((s) => s['bookings'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 5,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < _popularServices.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _popularServices[value.toInt()]['name'].toString().substring(0, 3),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(_popularServices.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: _popularServices[i]['bookings'].toDouble(),
                            color: Colors.blue,
                            width: 20,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }
        
        final service = _popularServices[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getServiceColor(index - 1).withOpacity(0.1),
              child: Text(
                '${index}',
                style: TextStyle(
                  color: _getServiceColor(index - 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(service['name'] as String),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${service['bookings']} bookings'),
                Text('Revenue: ${_formatCurrency(service['revenue'] as double)}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (service['growth'] as double) >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (service['growth'] as double) >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 16,
                    color: (service['growth'] as double) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${service['growth'].toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: (service['growth'] as double) >= 0
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Generate Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildReportCard(
          'Daily Summary',
          'Overview of today\'s bookings and revenue',
          Icons.today,
          Colors.blue,
          () => _generateReport('daily'),
        ),
        _buildReportCard(
          'Weekly Report',
          'Complete weekly performance analysis',
          Icons.calendar_view_week,
          Colors.green,
          () => _generateReport('weekly'),
        ),
        _buildReportCard(
          'Monthly Report',
          'Monthly statistics and trends',
          Icons.calendar_month,
          Colors.orange,
          () => _generateReport('monthly'),
        ),
        _buildReportCard(
          'Service Performance',
          'Detailed analysis by service type',
          Icons.spa,
          Colors.purple,
          () => _generateReport('services'),
        ),
        _buildReportCard(
          'Customer Insights',
          'Customer behavior and retention',
          Icons.people,
          Colors.teal,
          () => _generateReport('customers'),
        ),
        _buildReportCard(
          'Revenue Analysis',
          'Detailed revenue breakdown',
          Icons.attach_money,
          Colors.red,
          () => _generateReport('revenue'),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.download),
        onTap: onTap,
      ),
    );
  }

  Widget _buildKPICard(
    String label,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trend.startsWith('+') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10,
                      color: trend.startsWith('+') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueKPICard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieChart() {
    final stats = {
      'pending': _analyticsData?['pending_bookings']?.toDouble() ?? 0,
      'confirmed': _analyticsData?['confirmed_bookings']?.toDouble() ?? 0,
      'completed': _analyticsData?['completed_bookings']?.toDouble() ?? 0,
      'cancelled': _analyticsData?['cancelled_bookings']?.toDouble() ?? 0,
    };

    final total = stats.values.reduce((a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 150,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: stats['pending']!,
              title: '${((stats['pending']! / total) * 100).toStringAsFixed(1)}%',
              color: Colors.orange,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              value: stats['confirmed']!,
              title: '${((stats['confirmed']! / total) * 100).toStringAsFixed(1)}%',
              color: Colors.green,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              value: stats['completed']!,
              title: '${((stats['completed']! / total) * 100).toStringAsFixed(1)}%',
              color: Colors.blue,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              value: stats['cancelled']!,
              title: '${((stats['cancelled']! / total) * 100).toStringAsFixed(1)}%',
              color: Colors.red,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 30,
        ),
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Pending', Colors.orange, _analyticsData?['pending_bookings'] ?? 0),
        const SizedBox(height: 4),
        _buildLegendItem('Confirmed', Colors.green, _analyticsData?['confirmed_bookings'] ?? 0),
        const SizedBox(height: 4),
        _buildLegendItem('Completed', Colors.blue, _analyticsData?['completed_bookings'] ?? 0),
        const SizedBox(height: 4),
        _buildLegendItem('Cancelled', Colors.red, _analyticsData?['cancelled_bookings'] ?? 0),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: $count'),
      ],
    );
  }

  int _calculateAverageDaily() {
    if (_bookingTrends.isEmpty) return 0;
    final total = _bookingTrends.fold<int>(
      0,
      (sum, item) => sum + (item['total'] as int),
    );
    return (total / _bookingTrends.length).round();
  }

  Color _getServiceColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    return colors[index % colors.length];
  }

  void _generateReport(String type) {
    // This would generate and download a PDF/CSV report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $type report...'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Simulate report generation
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type report generated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _exportReport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF Format'),
              subtitle: const Text('Best for printing and sharing'),
              onTap: () {
                Navigator.pop(context);
                _generateReport('PDF');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('CSV Format'),
              subtitle: const Text('Best for data analysis'),
              onTap: () {
                Navigator.pop(context);
                _generateReport('CSV');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Image Format'),
              subtitle: const Text('Best for presentations'),
              onTap: () {
                Navigator.pop(context);
                _generateReport('Image');
              },
            ),
          ],
        ),
      ),
    );
  }
}