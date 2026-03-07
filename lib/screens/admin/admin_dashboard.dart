import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/constants/routes.dart';
import '../../core/utils/formatters.dart';
import 'manage_services_screen.dart';
import 'manage_slots_screen.dart';
import 'manage_bookings_screen.dart';
import 'analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _DashboardTab(),
      const ManageServicesScreen(),
      const ManageSlotsScreen(),
      const ManageBookingsScreen(),
      const AnalyticsScreen(),
    ];
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    
    await Future.wait([
      bookingProvider.fetchDashboardStats(),
      serviceProvider.fetchServices(includeInactive: true),
      serviceProvider.fetchServiceStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      authProvider.currentUser?.initials ?? 'A',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.currentUser?.name ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authProvider.currentUser?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.spa),
              title: const Text('Manage Services'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Manage Slots'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Manage Bookings'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final stats = bookingProvider.dashboardStats;

    if (bookingProvider.isLoading && stats == null) {
      return const LoadingIndicator();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await bookingProvider.fetchDashboardStats();
        await serviceProvider.fetchServices(includeInactive: true);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Formatters.getGreeting()}, Admin!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Here\'s what\'s happening today',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  'Today\'s Bookings',
                  stats?['today_bookings']?.toString() ?? '0',
                  Icons.today,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Pending',
                  stats?['pending_bookings']?.toString() ?? '0',
                  Icons.pending,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Confirmed',
                  stats?['confirmed_bookings']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Completed',
                  stats?['completed_bookings']?.toString() ?? '0',
                  Icons.done_all,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Cancelled',
                  stats?['cancelled_bookings']?.toString() ?? '0',
                  Icons.cancel,
                  Colors.red,
                ),
                _buildStatCard(
                  'Total Services',
                  stats?['total_services']?.toString() ?? 
                      serviceProvider.services.length.toString(),
                  Icons.spa,
                  Colors.teal,
                ),
                _buildStatCard(
                  'Total Users',
                  stats?['total_users']?.toString() ?? '0',
                  Icons.people,
                  Colors.indigo,
                ),
                _buildStatCard(
                  'Total Bookings',
                  stats?['total_bookings']?.toString() ?? '0',
                  Icons.event,
                  Colors.deepOrange,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent bookings
            const Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (stats?['recent_bookings'] != null)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats!['recent_bookings'].length,
                itemBuilder: (context, index) {
                  final booking = stats['recent_bookings'][index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          booking['user_name']?[0] ?? 'U',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      title: Text(booking['service_name'] ?? ''),
                      subtitle: Text(booking['user_name'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking['status']?.toString().toUpperCase() ?? '',
                          style: TextStyle(
                            color: _getStatusColor(booking['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        // Navigate to booking detail
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}