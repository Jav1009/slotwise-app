import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/booking_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../core/utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Last 30 Days';

  final List<String> _periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    
    await Future.wait([
      bookingProvider.fetchAnalytics(
        Formatters.formatApiDate(_startDate),
        Formatters.formatApiDate(_endDate),
      ),
      serviceProvider.fetchServiceStats(),
      bookingProvider.fetchDashboardStats(),
    ]);
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
        case 'Custom Range':
          _showDateRangePicker();
          return;
      }
      
      _loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingProvider, ServiceProvider>(
      builder: (context, bookingProvider, serviceProvider, child) {
        final stats = bookingProvider.dashboardStats;
        final analytics = bookingProvider.analytics;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analytics'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
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
              ),
            ),
          ),
          body: bookingProvider.isLoading
              ? const LoadingIndicator()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary cards
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildSummaryCard(
                            'Total Bookings',
                            stats?['total_bookings']?.toString() ?? '0',
                            Icons.event,
                            Colors.blue,
                          ),
                          _buildSummaryCard(
                            'Completed',
                            stats?['completed_bookings']?.toString() ?? '0',
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildSummaryCard(
                            'Revenue',
                            '\$${_calculateRevenue(analytics)}',
                            Icons.attach_money,
                            Colors.orange,
                          ),
                          _buildSummaryCard(
                            'Avg. Daily',
                            _calculateAverageDaily(analytics),
                            Icons.trending_up,
                            Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Booking trends chart
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
                            height: 250,
                            child: analytics.isEmpty
                                ? Center(
                                    child: Text(
                                      'No data available for this period',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  )
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
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() >= 0 && 
                                                  value.toInt() < analytics.length) {
                                                final date = DateTime.parse(
                                                  analytics[value.toInt()]['date']
                                                );
                                                return Text(
                                                  '${date.day}/${date.month}',
                                                  style: const TextStyle(fontSize: 10),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              return Text(value.toInt().toString());
                                            },
                                          ),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: analytics.asMap().entries.map((entry) {
                                            return FlSpot(
                                              entry.key.toDouble(),
                                              entry.value['total'].toDouble(),
                                            );
                                          }).toList(),
                                          isCurved: true,
                                          color: Theme.of(context).primaryColor,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(show: false),
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

                      // Status breakdown
                      const Text(
                        'Booking Status Breakdown',
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
                            height: 200,
                            child: stats == null
                                ? const Center(child: CircularProgressIndicator())
                                : PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          value: (stats['pending_bookings'] ?? 0).toDouble(),
                                          title: '${stats['pending_bookings']}',
                                          color: Colors.orange,
                                          radius: 80,
                                          titleStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value: (stats['confirmed_bookings'] ?? 0).toDouble(),
                                          title: '${stats['confirmed_bookings']}',
                                          color: Colors.green,
                                          radius: 80,
                                          titleStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value: (stats['completed_bookings'] ?? 0).toDouble(),
                                          title: '${stats['completed_bookings']}',
                                          color: Colors.blue,
                                          radius: 80,
                                          titleStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value: (stats['cancelled_bookings'] ?? 0).toDouble(),
                                          title: '${stats['cancelled_bookings']}',
                                          color: Colors.red,
                                          radius: 80,
                                          titleStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Popular services
                      const Text(
                        'Popular Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildServiceRanking(
                                1,
                                'Haircut',
                                45,
                                Colors.amber,
                              ),
                              const Divider(),
                              _buildServiceRanking(
                                2,
                                'Beard Trim',
                                32,
                                Colors.blue,
                              ),
                              const Divider(),
                              _buildServiceRanking(
                                3,
                                'Full Service',
                                28,
                                Colors.green,
                              ),
                              const Divider(),
                              _buildServiceRanking(
                                4,
                                'Hair Styling',
                                21,
                                Colors.orange,
                              ),
                              const Divider(),
                              _buildServiceRanking(
                                5,
                                'Hair Coloring',
                                15,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRanking(int rank, String name, int bookings, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$bookings bookings',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _calculateRevenue(List<Map<String, dynamic>> analytics) {
    // This would be calculated from actual booking data
    // Placeholder implementation
    return '2,450';
  }

  String _calculateAverageDaily(List<Map<String, dynamic>> analytics) {
    if (analytics.isEmpty) return '0';
    
    final total = analytics.fold<int>(
      0,
      (sum, item) => sum + (item['total'] as int),
    );
    final average = (total / analytics.length).toStringAsFixed(1);
    return average;
  }
}