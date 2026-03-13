// lib/screens/customer/customer_shell.dart
//
// Customer home shell — PageView with custom animated bottom nav.
// Tabs: Home | Book | My Bookings | Profile
//
// Home tab contains:
//   • WelcomeHeader (greeting + name + notification icon)
//   • ServiceSearchBar (autocomplete)
//   • OverviewStatsRow (services / bookings / categories)
//   • UpcomingBookingsRow (next 5 bookings, horizontal)
//
// All widgets from home_widgets.dart — themed via SlotWiseColors.
//
// Changes:
//   • NotificationProvider.startPolling() called on init — live badge updates
//   • BookingProvider refresh also tied to polling (30s interval via my_bookings_screen)
//   • stopPolling() called on dispose

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/service_model.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/settings_dialog.dart';
import '../customer/service_screen.dart';
import '../customer/my_bookings_screen.dart';
import '../customer/profile_screen.dart';
import '../customer/slot_picker_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> with WidgetsBindingObserver {
  final _pageCtrl = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<ServiceProvider>();
      svc.fetchServices();
      svc.fetchCategories();
      context.read<BookingProvider>().fetchMyBookings();
      // startPolling handles the 30s interval + first immediate fetch
      context.read<NotificationProvider>().startPolling();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationProvider>().fetchNotifications();
      context.read<BookingProvider>().fetchMyBookings();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    context.read<NotificationProvider>().stopPolling();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _pageCtrl.jumpToPage(index);
  }

  void _onServiceSelected(BuildContext ctx, ServiceModel svc) {
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => SlotPickerScreen(service: svc),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SlotWiseColors>()!;

    return Scaffold(
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(), // nav-bar controls paging
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: [
          // ── Tab 0: Home ────────────────────────────────────
          _HomeTab(onServiceSelected: (svc) => _onServiceSelected(context, svc)),

          // ── Tab 1: Book (Services) ─────────────────────────
          const ServicesScreen(),

          // ── Tab 2: My Bookings ─────────────────────────────
          const MyBookingsScreen(),

          // ── Tab 3: Profile ─────────────────────────────────
          const ProfileScreen(),
        ],
      ),

      // ── Custom bottom navigation ───────────────────────────
      bottomNavigationBar: _SlotWiseBottomNav(
        currentIndex: _currentIndex,
        onTap: _goTo,
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final void Function(ServiceModel) onServiceSelected;
  const _HomeTab({required this.onServiceSelected});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SlotWiseColors>()!;

    return Column(
      children: [
        // Header (includes status bar padding)
        const WelcomeHeader(),

        // Scrollable body
        Expanded(
          child: RefreshIndicator(
            color: c.primaryColor,
            onRefresh: () async {
              await Future.wait([
                context.read<ServiceProvider>().fetchServices(),
                context.read<BookingProvider>().fetchMyBookings(),
                context.read<NotificationProvider>().fetchNotifications(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  ServiceSearchBar(onServiceSelected: onServiceSelected),
                  const SizedBox(height: 20),

                  // Overview
                  _SectionLabel('Overview'),
                  const SizedBox(height: 10),
                  const OverviewStatsRow(),
                  const SizedBox(height: 20),

                  // Upcoming bookings
                  _SectionLabel('Upcoming Bookings'),
                  const SizedBox(height: 10),
                  const UpcomingBookingsRow(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SlotWiseColors>()!;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: c.primaryColor,
        letterSpacing: 0.1,
      ),
    );
  }
}

// ─── Custom Bottom Navigation Bar ────────────────────────────────────────────
class _SlotWiseBottomNav extends StatelessWidget {
  final int         currentIndex;
  final ValueChanged<int> onTap;

  const _SlotWiseBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<SlotWiseColors>()!;

    final items = [
      (icon: Icons.home_outlined,     activeIcon: Icons.home,          label: 'Home'),
      (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Book'),
      (icon: Icons.bookmark_outline,  activeIcon: Icons.bookmark,      label: 'My'),
      (icon: Icons.person_outline,    activeIcon: Icons.person,        label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        boxShadow: [
          BoxShadow(
            color: c.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: c.primaryColor.withOpacity(0.06), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: List.generate(items.length, (i) {
              final item     = items[i];
              final selected = currentIndex == i;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated icon with soft pill background
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: selected ? 16 : 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? c.accentSoft : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 22,
                            color: selected
                                ? c.navActiveTint
                                : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? c.navActiveTint : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}