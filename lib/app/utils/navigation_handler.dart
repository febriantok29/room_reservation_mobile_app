import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/pages/login_page.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';

/// Handler untuk navigasi global
class NavigationHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Track if we're already handling an unauthorized state to prevent multiple redirects
  static bool _isHandlingUnauthorized = false;

  /// Handle unauthorized access (token expired)
  static Future<void> handleUnauthorized() async {
    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;

    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        return;
      }

      // Hapus token dan navigate ke login
      // Note: logout should have already been called by the caller, but we'll ensure it here
      final authService = await AuthService.getInstance();
      if (authService.isLoggedIn()) {
        await authService.logout();
      }

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } finally {
      // Reset flag after navigation completes or fails
      _isHandlingUnauthorized = false;
    }
  }
}
