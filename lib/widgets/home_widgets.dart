// lib/widgets/home_widgets.dart
//
// Reusable widgets that compose the customer Home tab:
//
//   WelcomeHeader        — greeting + username + notification icon
//   ServiceSearchBar     — autocomplete against live service list
//   OverviewStatsRow     — 3 stat cards: services / bookings / categories
//   UpcomingBookingsRow  — horizontal scroll of next 5 upcoming bookings
//
// All widgets read from their respective Providers.
// They adapt to the current SlotWiseColors theme extension.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../providers/booking_provider.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';
import 'notification_dialog.dart';

// ─── 1. Welcome Header ────────────────────────────────────────────────────────
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final c    = Theme.of(context).extension<SlotWiseColors>()!;
    final user = context.watch<AuthProvider>().user;

    return Container(
      decoration: BoxDecoration(
        color: c.headerBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, MediaQuery.of(context).padding.top + 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.firstName ?? 'Welcome',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Notification button (white icon on coloured header)
          const NotificationIconButton(iconColor: Colors.white),
        ],
      ),
    );
  }
}

// ─── 2. Service Search Bar ────────────────────────────────────────────────────
// Autocomplete: as you type it checks if the input matches any service name
// (case-insensitive, substring match). Tapping a suggestion navigates to
// slot picker for that service.

class ServiceSearchBar extends StatefulWidget {
  /// Called with the selected ServiceModel when user picks a suggestion.
  final void Function(ServiceModel service)? onServiceSelected;

  const ServiceSearchBar({super.key, this.onServiceSelected});

  @override
  State<ServiceSearchBar> createState() => _ServiceSearchBarState();
}

class _ServiceSearchBarState extends State<ServiceSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services;
    final c        = Theme.of(context).extension<SlotWiseColors>()!;

    return Autocomplete<ServiceModel>(
      optionsBuilder: (TextEditingValue tv) {
        if (tv.text.isEmpty) return const [];
        return services.where((s) =>
            s.name.toLowerCase().contains(tv.text.toLowerCase()) ||
            (s.category?.toLowerCase().contains(tv.text.toLowerCase()) ?? false));
      },
      displayStringForOption: (s) => s.name,
      onSelected: (s) {
        _ctrl.clear();
        widget.onServiceSelected?.call(s);
      },
      fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => TextField(
        controller: ctrl,
        focusNode: focus,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          hintText: 'Search services...',
          prefixIcon: Icon(Icons.search, color: c.primaryColor.withOpacity(0.5)),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () { ctrl.clear(); setState(() {}); },
                )
              : null,
          filled: true,
          fillColor: c.isDark
              ? Colors.white.withOpacity(0.06)
              : c.primaryColor.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: c.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      optionsViewBuilder: (ctx, onSel, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              children: options.map((svc) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: c.accentSoft,
                  child: Text(
                    svc.name[0],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.primaryColor,
                    ),
                  ),
                ),
                title: Text(svc.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(svc.formattedPrice,
                    style: TextStyle(fontSize: 11, color: c.accentColor)),
                trailing: svc.category != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(svc.category!,
                            style: TextStyle(fontSize: 9, color: c.primaryColor)),
                      )
                    : null,
                onTap: () => onSel(svc),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 3. Overview Stats Row ────────────────────────────────────────────────────
class OverviewStatsRow extends StatelessWidget {
  const OverviewStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c        = Theme.of(context).extension<SlotWiseColors>()!;
    final services = context.watch<ServiceProvider>();
    final bookings = context.watch<BookingProvider>();

    final stats = [
      (
        label: 'Services',
        value: '${services.services.length}',
        icon: Icons.design_services_outlined,
      ),
      (
        label: 'My Bookings',
        value: '${bookings.bookings.length}',
        icon: Icons.calendar_month_outlined,
      ),
      (
        label: 'Categories',
        value: '${services.categories.length}',
        icon: Icons.category_outlined,
      ),
    ];

    return Row(
      children: stats.map((s) {
        final isLast = s == stats.last;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.primaryColor.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Icon(s.icon, size: 22, color: c.primaryColor),
                const SizedBox(height: 6),
                Text(
                  s.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── 4. Upcoming Bookings Row ─────────────────────────────────────────────────
class UpcomingBookingsRow extends StatelessWidget {
  const UpcomingBookingsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c        = Theme.of(context).extension<SlotWiseColors>()!;
    final upcoming = context.watch<BookingProvider>().upcoming.take(5).toList();

    if (upcoming.isEmpty) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.primaryColor.withOpacity(0.08)),
        ),
        child: Center(
          child: Text(
            'No upcoming bookings',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: upcoming.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _UpcomingCard(booking: upcoming[i], c: c),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final BookingModel   booking;
  final SlotWiseColors c;

  const _UpcomingCard({required this.booking, required this.c});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(booking.status);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primaryColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            booking.serviceName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.primaryColor,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.schedule, size: 11, color: Colors.grey[400]),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  _formatDate(booking.slotDate, booking.startTime),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date, String startTime) {
    if (date == null) return startTime.substring(0, 5);
    try {
      final d   = DateTime.parse(date);
      final now = DateTime.now();
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return 'Today · ${startTime.substring(0, 5)}';
      }
      final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff == 1) return 'Tomorrow · ${startTime.substring(0, 5)}';
      return '${DateFormat('MMM d').format(d)} · ${startTime.substring(0, 5)}';
    } catch (_) {
      return startTime.substring(0, 5);
    }
  }
}