import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../core/constants/routes.dart';
import '../../core/utils/formatters.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({Key? key}) : super(key: key);

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['all', 'pending', 'confirmed', 'completed', 'cancelled'];
  String _selectedStatus = 'all';
  DateTime? _selectedDate;
  Service? _selectedService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    
    await Future.wait([
      bookingProvider.fetchAllBookings(),
      serviceProvider.fetchServices(),
    ]);
  }

  Future<void> _filterBookings() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.fetchAllBookings(
      status: _selectedStatus != 'all' ? _selectedStatus : null,
      date: _selectedDate != null ? Formatters.formatApiDate(_selectedDate!) : null,
      serviceId: _selectedService?.id,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['all', 'pending', 'confirmed', 'completed', 'cancelled']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Date filter
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null
                              ? Formatters.formatDate(_selectedDate!)
                              : 'Select date',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                const SizedBox(height: 12),
                
                // Service filter
                Consumer<ServiceProvider>(
                  builder: (context, serviceProvider, child) {
                    return DropdownButtonFormField<Service>(
                      value: _selectedService,
                      decoration: const InputDecoration(
                        labelText: 'Service',
                        border: OutlineInputBorder(),
                      ),
                      items: serviceProvider.services.map((service) {
                        return DropdownMenuItem(
                          value: service,
                          child: Text(service.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedService = value;
                        });
                      },
                    );
                  },
                ),
                if (_selectedService != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedService = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _filterBookings();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(Booking booking, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Booking Status'),
        content: Text(
          'Are you sure you want to mark this booking as ${newStatus.toUpperCase()}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.updateBookingStatus(booking.id, newStatus);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking marked as ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        return Column(
          children: [
            // Filter bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search bookings...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        // Implement search
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterDialog,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),

            // Stats summary
            if (bookingProvider.dashboardStats != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatChip(
                          'Pending',
                          bookingProvider.dashboardStats!['pending_bookings']?.toString() ?? '0',
                          Colors.orange,
                        ),
                        _buildStatChip(
                          'Confirmed',
                          bookingProvider.dashboardStats!['confirmed_bookings']?.toString() ?? '0',
                          Colors.green,
                        ),
                        _buildStatChip(
                          'Completed',
                          bookingProvider.dashboardStats!['completed_bookings']?.toString() ?? '0',
                          Colors.blue,
                        ),
                        _buildStatChip(
                          'Cancelled',
                          bookingProvider.dashboardStats!['cancelled_bookings']?.toString() ?? '0',
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // Bookings list
            Expanded(
              child: bookingProvider.isLoading
                  ? const LoadingIndicator()
                  : bookingProvider.allBookings.isEmpty
                      ? EmptyState(
                          icon: Icons.book,
                          message: 'No bookings found',
                          subtitle: 'Try adjusting your filters',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: bookingProvider.allBookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookingProvider.allBookings[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                        child: Text(
                                          booking.userName?[0] ?? 'U',
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                      title: Text(booking.serviceName),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(booking.userName ?? 'Unknown User'),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${Formatters.formatDate(booking.slotDate)} at ${Formatters.formatTime(booking.slotStartTime)}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      trailing: StatusBadge(
                                        status: booking.statusText,
                                        color: booking.statusColor,
                                        small: true,
                                      ),
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.bookingDetail,
                                          arguments: booking.id,
                                        );
                                      },
                                    ),
                                    if (booking.isPending || booking.isConfirmed)
                                      ButtonBar(
                                        children: [
                                          if (booking.isPending) ...[
                                            TextButton(
                                              onPressed: () => _updateBookingStatus(booking, 'confirmed'),
                                              child: const Text('Confirm'),
                                            ),
                                            TextButton(
                                              onPressed: () => _updateBookingStatus(booking, 'cancelled'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Cancel'),
                                            ),
                                          ],
                                          if (booking.isConfirmed)
                                            TextButton(
                                              onPressed: () => _updateBookingStatus(booking, 'completed'),
                                              child: const Text('Mark Completed'),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}