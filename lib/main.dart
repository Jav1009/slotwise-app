import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/slot_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'widgets/notification_handler.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  DioClient().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => SlotProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          return MaterialApp(
            title: 'SlotWise',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/services': (context) => const ServicesScreen(),
              '/service-detail': (context) {
                final serviceId = ModalRoute.of(context)!.settings.arguments as int;
                return ServiceDetailScreen(serviceId: serviceId);
              },
              '/slot-picker': (context) {
                final service = ModalRoute.of(context)!.settings.arguments;
                return SlotPickerScreen(service: service);
              },
              '/booking-confirm': (context) {
                final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return BookingConfirmScreen(arguments: arguments);
              },
              '/my-bookings': (context) => const MyBookingsScreen(),
              '/booking-detail': (context) {
                final bookingId = ModalRoute.of(context)!.settings.arguments as int;
                return BookingDetailScreen(bookingId: bookingId);
              },
              '/profile': (context) => const ProfileScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/admin': (context) => const AdminDashboard(),
              '/admin/services': (context) => const ManageServicesScreen(),
              '/admin/slots': (context) => const ManageSlotsScreen(),
              '/admin/bookings': (context) => const ManageBookingsScreen(),
              '/admin/analytics': (context) => const AnalyticsScreen(),
            },
            builder: (context, child) {
              return NotificationHandler(
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
