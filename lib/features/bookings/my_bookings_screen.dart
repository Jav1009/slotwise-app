// lib/features/bookings/my_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/booking_model.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // Simple integer — completely immune to Provider rebuilds
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark
        ? const Color(0xFF1E1E1E)
        : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBg,
        title: const Text('My Bookings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: appBarBg,
            child: Row(
              children: [
                _TabButton(
                  label: 'Upcoming',
                  isSelected: _selectedIndex == 0,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _TabButton(
                  label: 'Past',
                  isSelected: _selectedIndex == 1,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
      // IndexedStack keeps both lists mounted so scroll position
      // is preserved when switching tabs
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Failed to load bookings',
                      style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: provider.fetchMyBookings,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return IndexedStack(
            index: _selectedIndex,
            children: [
              _BookingsList(
                bookings: provider.upcomingBookings,
                onRefresh: provider.fetchMyBookings,
                isDark: isDark,
              ),
              _BookingsList(
                bookings: provider.pastBookings,
                onRefresh: provider.fetchMyBookings,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Custom tab button ─────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bookings list ─────────────────────────────────────────────

class _BookingsList extends StatelessWidget {
  final List<BookingModel> bookings;
  final Future<void> Function() onRefresh;
  final bool isDark;

  const _BookingsList({
    required this.bookings,
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy,
                size: 64,
                color:
                    isDark ? Colors.white38 : AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(
                  fontSize: 18,
                  color: isDark
                      ? Colors.white54
                      : AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _BookingCard(
            booking: booking,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(booking: booking),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Booking card ──────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final bool isDark;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor  = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final metaColor  =
        isDark ? Colors.white54 : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceName,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: booking.statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.statusText,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: booking.statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: metaColor),
                  const SizedBox(width: 8),
                  Text(booking.formattedDate,
                      style: TextStyle(
                          fontSize: 14, color: metaColor)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: metaColor),
                  const SizedBox(width: 8),
                  Text(booking.formattedTimeRange,
                      style: TextStyle(
                          fontSize: 14, color: metaColor)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booking.formattedPrice,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}