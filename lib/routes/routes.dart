// lib/core/navigation/routes.dart
//
// ─── SlotWise Central Route Registry ────────────────────────────────────────
//
// USAGE — Named route navigation:
//   Navigator.pushNamed(context, AppRoutes.login);
//   Navigator.pushNamed(context, AppRoutes.bookingDetail,
//       arguments: BookingDetailArgs(booking: myBooking));
//
// USAGE — Push and remove all previous routes (e.g. after login):
//   Navigator.pushNamedAndRemoveUntil(
//       context, AppRoutes.customerHome, (r) => false);
//
// USAGE — Pop back:
//   Navigator.pop(context);
//
// STRUCTURE:
//   AppRoutes     — const route name strings (single source of truth)
//   AppRouter     — onGenerateRoute handler, plug into MaterialApp
//   *Args classes — typed argument containers for screens that need data
//
// WHY onGenerateRoute instead of plain routes: {}?
//   The plain routes map can't pass typed arguments. onGenerateRoute gives us
//   full control: we extract typed args, catch unknown routes, and guard
//   role-protected screens in one place.

import 'package:flutter/material.dart';
import 'package:slot_wise_booking/models/slot_model.dart';
import 'package:slot_wise_booking/screens/nav/layout_nav.dart';

// ── Screen imports ────────────────────────────────────────────────────────────
import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/customer/service_screen.dart';
import '../../screens/customer/slot_picker_screen.dart';
import '../../screens/customer/booking_confirm_screen.dart';
import '../../screens/customer/booking_detail_screen.dart';
import '../../screens/customer/my_bookings_screen.dart';
import '../../screens/customer/reschedule_screen.dart';
import '../../screens/customer/profile_screen.dart';
import '../../screens/customer/edit_profile_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/manage_services_screen.dart';
import '../../screens/admin/manage_slots_screen.dart';
import '../../screens/admin/manage_bookings_screen.dart';
import '../../screens/staff/staff_dashboard_screen.dart';
import '../../models/booking_model.dart';
import '../../models/service_model.dart';

// ─── Route name constants ─────────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────
  static const String splash         = '/';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Customer ──────────────────────────────────────────────
  /// Shell with PageView + bottom nav (Home / Book / My Bookings / Profile)
  static const String customerHome   = '/home';
  static const String services       = '/services';
  static const String slotPicker     = '/slot-picker';
  static const String bookingConfirm = '/booking-confirm';
  static const String bookingDetail  = '/booking-detail';
  static const String myBookings     = '/my-bookings';
  static const String reschedule     = '/reschedule';
  static const String profile        = '/profile';
  static const String editProfile    = '/edit-profile';

  // ── Staff ─────────────────────────────────────────────────
  static const String staffDashboard = '/staff';

  // ── Admin ─────────────────────────────────────────────────
  static const String adminDashboard    = '/admin';
  static const String manageServices    = '/admin/services';
  static const String manageSlots       = '/admin/slots';
  static const String manageBookings    = '/admin/bookings';
}

// ─── Typed argument containers ────────────────────────────────────────────────
// Use these instead of raw dynamic maps so you get compile-time safety.

/// SlotPickerScreen — requires the service the customer chose
class SlotPickerArgs {
  final ServiceModel service;
  const SlotPickerArgs({required this.service});
}

/// BookingDetailScreen — requires the booking to display
class BookingDetailArgs {
  final BookingModel booking;
  const BookingDetailArgs({required this.booking});
}

/// RescheduleScreen — requires both booking and its service
class RescheduleArgs {
  final BookingModel booking;
  final ServiceModel service;
  const RescheduleArgs({required this.booking, required this.service});
}

/// BookingConfirmScreen — requires service + selected slot id + slot time
class BookingConfirmArgs {
  final ServiceModel service;
  final SlotModel          slot;
  const BookingConfirmArgs({
    required this.service,
    required this.slot,
    
  });
}

// ─── Route generator ─────────────────────────────────────────────────────────
class AppRouter {
  AppRouter._();

  /// Plug into MaterialApp:
  ///   onGenerateRoute: AppRouter.onGenerateRoute,
  ///   initialRoute: AppRoutes.splash,
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {

      // ── Auth ────────────────────────────────────────────────
      case AppRoutes.splash:
        return _slide(const SplashScreen(), settings);

      case AppRoutes.login:
        return _slide(const LoginScreen(), settings);

      case AppRoutes.register:
        return _slide(const RegisterScreen(), settings);

      case AppRoutes.forgotPassword:
        return _slide(const ForgotPasswordScreen(), settings);

      // ── Customer ────────────────────────────────────────────
      case AppRoutes.customerHome:
        return _fade(const CustomerShell(), settings);

      case AppRoutes.services:
        return _slide(const ServicesScreen(), settings);

      case AppRoutes.slotPicker:
        if (args is SlotPickerArgs) {
          return _slide(SlotPickerScreen(service: args.service), settings);
        }
        return _errorRoute(settings.name, 'Expected SlotPickerArgs');

      case AppRoutes.bookingConfirm:
        if (args is BookingConfirmArgs) {
          return _slide(
            BookingConfirmScreen(
              service:   args.service,
              slot: args.slot,
              // slotId:    args.slotId,
              // slotDate:  args.slotDate,
              // startTime: args.startTime,
              // endTime:   args.endTime,
            ),
            settings,
          );
        }
        return _errorRoute(settings.name, 'Expected BookingConfirmArgs');

      case AppRoutes.bookingDetail:
        if (args is BookingDetailArgs) {
          return _slide(BookingDetailScreen(booking: args.booking), settings);
        }
        return _errorRoute(settings.name, 'Expected BookingDetailArgs');

      case AppRoutes.myBookings:
        return _slide(const MyBookingsScreen(), settings);

      case AppRoutes.reschedule:
        if (args is RescheduleArgs) {
          return _slide(
            RescheduleScreen(booking: args.booking, service: args.service),
            settings,
          );
        }
        return _errorRoute(settings.name, 'Expected RescheduleArgs');

      case AppRoutes.profile:
        return _slide(const ProfileScreen(), settings);

      case AppRoutes.editProfile:
        return _slide(const EditProfileScreen(), settings);

      // ── Staff ───────────────────────────────────────────────
      case AppRoutes.staffDashboard:
        return _fade(const StaffDashboardScreen(), settings);

      // ── Admin ───────────────────────────────────────────────
      case AppRoutes.adminDashboard:
        return _fade(const AdminDashboardScreen(), settings);

      case AppRoutes.manageServices:
        return _slide(const ManageServicesScreen(), settings);

      case AppRoutes.manageSlots:
        return _slide(const ManageSlotsScreen(), settings);

      case AppRoutes.manageBookings:
        return _slide(const ManageBookingsScreen(), settings);

      // ── 404 ─────────────────────────────────────────────────
      default:
        return _errorRoute(settings.name, 'Route not found');
    }
  }

  // ── Transition helpers ───────────────────────────────────────────────────────

  /// Standard right-to-left slide (used for most pushes)
  static PageRouteBuilder<T> _slide<T>(Widget page, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end:   Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      );

  /// Fade transition (used for dashboard / shell swaps — feels less "push-y")
  static PageRouteBuilder<T> _fade<T>(Widget page, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 220),
      );

  /// Error route — shows a diagnostic screen instead of crashing
  static Route<dynamic> _errorRoute(String? routeName, String reason) =>
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Navigation Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Route: ${routeName ?? 'unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(reason, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─── Navigation helpers (optional shortcuts) ─────────────────────────────────
// Call these instead of Navigator.pushNamed to get autocomplete + type safety.
//
// Example:
//   AppNav.toSlotPicker(context, service: myService);
//   AppNav.toBookingDetail(context, booking: myBooking);

extension AppNav on BuildContext {
  // ── Auth ──────────────────────────────────────────────────
  void goLogin()    => Navigator.pushNamedAndRemoveUntil(
      this, AppRoutes.login, (_) => false);
  void goRegister() => Navigator.pushNamed(this, AppRoutes.register);
  void goForgotPassword() =>
      Navigator.pushNamed(this, AppRoutes.forgotPassword);

  // ── Customer ──────────────────────────────────────────────
  void goCustomerHome() => Navigator.pushNamedAndRemoveUntil(
      this, AppRoutes.customerHome, (_) => false);
  void goMyBookings()   => Navigator.pushNamed(this, AppRoutes.myBookings);
  void goProfile()      => Navigator.pushNamed(this, AppRoutes.profile);
  void goEditProfile()  => Navigator.pushNamed(this, AppRoutes.editProfile);

  void goSlotPicker(ServiceModel service) => Navigator.pushNamed(
      this, AppRoutes.slotPicker,
      arguments: SlotPickerArgs(service: service));

  void goBookingDetail(BookingModel booking) => Navigator.pushNamed(
      this, AppRoutes.bookingDetail,
      arguments: BookingDetailArgs(booking: booking));

  void goReschedule(BookingModel booking, ServiceModel service) =>
      Navigator.pushNamed(
        this, AppRoutes.reschedule,
        arguments: RescheduleArgs(booking: booking, service: service),
      );

  void goBookingConfirm({
    required ServiceModel service,
    required SlotModel          slot,
  }) => Navigator.pushNamed(
      this, AppRoutes.bookingConfirm,
      arguments: BookingConfirmArgs(
        service:   service,
        slot:    slot,
      ));

  // ── Staff ─────────────────────────────────────────────────
  void goStaffDashboard() => Navigator.pushNamedAndRemoveUntil(
      this, AppRoutes.staffDashboard, (_) => false);

  // ── Admin ─────────────────────────────────────────────────
  void goAdminDashboard()  => Navigator.pushNamedAndRemoveUntil(
      this, AppRoutes.adminDashboard, (_) => false);
  void goManageServices()  =>
      Navigator.pushNamed(this, AppRoutes.manageServices);
  void goManageSlots()     =>
      Navigator.pushNamed(this, AppRoutes.manageSlots);
  void goManageBookings()  =>
      Navigator.pushNamed(this, AppRoutes.manageBookings);
}