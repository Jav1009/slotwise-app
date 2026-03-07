import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/services_screen.dart';
import 'screens/user/service_detail_screen.dart';
import 'screens/user/slot_picker_screen.dart';
import 'screens/user/booking_confirm_screen.dart';
import 'screens/user/my_bookings_screen.dart';
import 'screens/user/booking_detail_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/notifications_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/manage_services_screen.dart';
import 'screens/admin/manage_slots_screen.dart';
import 'screens/admin/manage_bookings_screen.dart';
import 'screens/admin/analytics_screen.dart';
import 'core/constants/routes.dart';

class SlotWiseApp extends StatelessWidget {
  const SlotWiseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        return MaterialApp(
          title: 'SlotWise',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AppRoutes.splash:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              case AppRoutes.login:
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case AppRoutes.register:
                return MaterialPageRoute(builder: (_) => const RegisterScreen());
              case AppRoutes.home:
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              case AppRoutes.services:
                return MaterialPageRoute(builder: (_) => const ServicesScreen());
              case AppRoutes.serviceDetail:
                final serviceId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(serviceId: serviceId),
                );
              case AppRoutes.slotPicker:
                final service = settings.arguments;
                return MaterialPageRoute(
                  builder: (_) => SlotPickerScreen(service: service),
                );
              case AppRoutes.bookingConfirm:
                final arguments = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => BookingConfirmScreen(arguments: arguments),
                );
              case AppRoutes.myBookings:
                return MaterialPageRoute(builder: (_) => const MyBookingsScreen());
              case AppRoutes.bookingDetail:
                final bookingId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(bookingId: bookingId),
                );
              case AppRoutes.profile:
                return MaterialPageRoute(builder: (_) => const ProfileScreen());
              case AppRoutes.notifications:
                return MaterialPageRoute(builder: (_) => const NotificationsScreen());
              case AppRoutes.adminDashboard:
                return MaterialPageRoute(builder: (_) => const AdminDashboard());
              case AppRoutes.manageServices:
                return MaterialPageRoute(builder: (_) => const ManageServicesScreen());
              case AppRoutes.manageSlots:
                return MaterialPageRoute(builder: (_) => const ManageSlotsScreen());
              case AppRoutes.manageBookings:
                return MaterialPageRoute(builder: (_) => const ManageBookingsScreen());
              case AppRoutes.analytics:
                return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
              default:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
            }
          },
        );
      },
    );
  }
}