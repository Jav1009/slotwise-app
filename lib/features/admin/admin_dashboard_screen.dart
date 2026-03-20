// lib/features/admin/admin_dashboard_screen.dart
// Admin home screen. Displays live stats cards, quick-action
// navigation buttons, and a popular services leaderboard.

// Always fetches all-time stats (no date range).
// Re-fetches when navigated back to from analytics or any child screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slotwise/features/admin/analytics_screen.dart';
import 'package:slotwise/widgets/admin_theme_wrapper.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'manage_services_screen.dart';
import 'manage_slots_screen.dart';
import 'manage_bookings_screen.dart';
import '../../main.dart'; // for routeObserver

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with RouteAware {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _fetchAllTime();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe so didPopNext fires when returning from a child route
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when a child route is popped and this screen is visible again.
  /// Re-fetches all-time stats so the dashboard is never left showing
  /// whatever date range the analytics screen last requested.
  @override
  void didPopNext() {
    _fetchAllTime();
  }

  /// Always fetches with NO date range = all-time totals.
  void _fetchAllTime() {
    context.read<AdminProvider>().fetchStats();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showAdminDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth  = context.watch<AuthProvider>();
    final name  = auth.currentUser?.name.split(' ').first ?? 'Admin';

    return SafeArea(
      child: AdminThemeWrapper(
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: RefreshIndicator(
            onRefresh: () async => _fetchAllTime(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _AdminHeader(
                    name: name,
                    onLogout: _handleLogout,
                    onRefresh: _fetchAllTime,
                  ),
                ),

                // ── Error banner ─────────────────────────────────────────
                if (admin.error != null)
                  SliverToBoxAdapter(
                    child: _ErrorBanner(
                        message: admin.error!, onRetry: _fetchAllTime),
                  ),

                // ── Stats grid ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: admin.isLoading && admin.stats == null
                        ? const _StatsShimmer()
                        : _StatsGrid(stats: admin.stats),
                  ),
                ),

                // ── Quick Actions title ──────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),

                // ── Action cards ─────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate([
                      _ActionCard(
                        icon: Icons.design_services_rounded,
                        label: 'Services',
                        subtitle: 'Add · Edit · Delete',
                        color: const Color(0xFF6C63FF),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ManageServicesScreen()),
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Slots',
                        subtitle: 'Schedule · Manage',
                        color: const Color(0xFF00B4D8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ManageSlotsScreen()),
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.book_online_rounded,
                        label: 'Bookings',
                        subtitle: 'Review · Update',
                        color: const Color(0xFFFF6B6B),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ManageBookingsScreen()),
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.bar_chart_rounded,
                        label: 'Analytics',
                        subtitle: 'Revenue · Trends',
                        color: const Color(0xFF06D6A0),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AnalyticsScreen()),
                        ),
                      ),
                    ]),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                    ),
                  ),
                ),

                // ── Popular services ──────────────────────────────────────
                if (admin.stats?.popularServices.isNotEmpty == true) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Popular Services',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final svc =
                              admin.stats!.popularServices[i];
                          return _PopularServiceTile(
                            rank: i + 1,
                            name: svc['name'] as String,
                            count:
                                (svc['booking_count'] as int?) ?? 0,
                            isTop: i == 0,
                          );
                        },
                        childCount:
                            admin.stats!.popularServices.length,
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                    child: SizedBox(height: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;

  const _AdminHeader({
    required this.name,
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white70),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white70),
                tooltip: 'Log out',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded,
                    color: AppColors.primary, size: 14),
                SizedBox(width: 4),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final AdminStats? stats;
  const _StatsGrid({this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: "Today's Bookings",
                value: '${stats?.todayBookings ?? 0}',
                icon: Icons.today_rounded,
                color: const Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '${stats?.pendingBookings ?? 0}',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFFFB347),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Bookings',
                value: '${stats?.totalBookings ?? 0}',
                icon: Icons.book_online_rounded,
                color: const Color(0xFF00B4D8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Revenue',
                value: stats != null
                    ? '\$${stats!.totalRevenue.toStringAsFixed(0)}'
                    : '\$0',
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF06D6A0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _shimmerBox()),
            const SizedBox(width: 12),
            Expanded(child: _shimmerBox()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _shimmerBox()),
            const SizedBox(width: 12),
            Expanded(child: _shimmerBox()),
          ],
        ),
      ],
    );
  }

  Widget _shimmerBox() => Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
      );
}

// ── Action Card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData     icon;
  final String       label, subtitle;
  final Color        color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12, top: -12,
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Popular Service Tile ──────────────────────────────────────────────────────

class _PopularServiceTile extends StatelessWidget {
  final int    rank, count;
  final String name;
  final bool   isTop;

  const _PopularServiceTile({
    required this.rank,
    required this.name,
    required this.count,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isTop
            ? Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isTop
                  ? AppColors.primary
                  : const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: isTop
                      ? Colors.white
                      : const Color(0xFF6C63FF),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count bookings',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorBanner(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 13)),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}