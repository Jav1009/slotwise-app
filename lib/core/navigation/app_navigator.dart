// lib/core/navigation/app_navigator.dart
//
// A single GlobalKey<NavigatorState> shared across the whole app.
//
// WHY:
//   Services and interceptors (like ApiService's 401 handler) run outside
//   the widget tree and have no BuildContext. This key gives them access to
//   the Navigator and ScaffoldMessenger without needing one.
//
// USAGE:
//   1. Pass it to MaterialApp:
//        MaterialApp(navigatorKey: AppNavigator.key, ...)
//
//   2. Navigate from anywhere:
//        AppNavigator.key.currentState?.pushNamed('/login');
//
//   3. Show snackbars from anywhere:
//        ScaffoldMessenger.of(AppNavigator.key.currentContext!)
//            .showSnackBar(...)

import 'package:flutter/material.dart';

class AppNavigator {
  // One instance for the lifetime of the app
  static final GlobalKey<NavigatorState> key =
      GlobalKey<NavigatorState>(debugLabel: 'root_navigator');

  AppNavigator._(); // prevent instantiation
}