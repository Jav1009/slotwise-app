// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:slotwise/data/services/fcm_service.dart';
import 'package:slotwise/features/admin/manage_bookings_screen.dart';
import 'package:slotwise/features/bookings/my_bookings_screen.dart';
import 'package:slotwise/providers/notification_provider.dart';
import 'package:slotwise/providers/theme_provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/admin_provider.dart';
import 'features/splash/splash_screen.dart';

/// Global navigator key — lets FCMService navigate without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global route observer — lets AdminDashboardScreen detect when it
/// becomes visible again after a child route pops.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMService().initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.loadFromPrefs();

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) => MaterialApp(
          title: 'SlotWise',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,
          home: const _AppLifecycleWrapper(child: SplashScreen()),
          // ── Named routes used by FCMService for push-notification taps ──
          routes: {
            '/bookings': (ctx) {
              final tab = ModalRoute.of(ctx)?.settings.arguments as int? ?? 0;
              return MyBookingsScreen(initialTab: tab);
            },
            '/admin/bookings': (ctx) {
              // The booking ID to highlight is passed as a route argument
              // by FCMService._pushAdminBookings().
              final id = ModalRoute.of(ctx)?.settings.arguments as int?;
              return ManageBookingsScreen(highlightBookingId: id);
            },
          },
        ),
      ),
    );
  }
}

// ── Lifecycle Wrapper ─────────────────────────────────────────
// Fixes the black screen on Samsung/aggressive-memory-management
// Android devices when returning from another app.

class _AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _AppLifecycleWrapper({required this.child});

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.reassembleApplication();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
