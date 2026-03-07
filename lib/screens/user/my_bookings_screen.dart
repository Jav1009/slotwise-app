import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../core/constants/routes.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabTitles = ['Upcoming', 'Pending', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  Future<void> _loadBookings() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.fetchMyBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
        // Tab content
        Expanded(
          child: Consumer<BookingProvider>(
            builder: (context, bookingProvider, child) {
              if (bookingProvider.isLoading && bookingProvider.myBookings.isEmpty) {
                return const LoadingIndicator();
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(
                    bookingProvider.upcomingBookings,
                    emptyMessage: 'No upcoming bookings',
                  ),
                  _buildBookingList(
                    bookingProvider.pendingBookings,
                    emptyMessage: 'No pending bookings',
                  ),
                  _buildBookingList(
                    bookingProvider.completedBookings,
                    emptyMessage: 'No completed bookings',
                  ),
                  _buildBookingList(
                    bookingProvider.cancelledBookings,
                    emptyMessage: 'No cancelled bookings',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingList(List<dynamic> bookings, {required String emptyMessage}) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        message: emptyMessage,
        subtitle: 'Your bookings will appear here',
        buttonText: 'Browse Services',
        onButtonPressed: () {
          final homeScreenState = context.findAncestorStateOfType();
          // Navigate to services tab
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingCard(
            booking: booking,
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.bookingDetail,
                arguments: booking.id,
              );
            },
          );
        },
      ),
    );
  }
}