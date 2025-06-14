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
    // Prevent multiple simultaneous redirects
    if (_isHandlingUnauthorized) {
      debugPrint(
        '🔄 NavigationHandler: Already handling unauthorized state, ignoring duplicate call',
      );
      return;
    }

    _isHandlingUnauthorized = true;

    try {
      debugPrint(
        '🚪 NavigationHandler: Handling unauthorized access, redirecting to login page',
      );

      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint(
          '⚠️ NavigationHandler: No valid BuildContext found for navigation',
        );
        return;
      }

      // Hapus token dan navigate ke login
      // Note: logout should have already been called by the caller, but we'll ensure it here
      final authService = await AuthService.getInstance();
      if (authService.isLoggedIn()) {
        debugPrint('🔑 NavigationHandler: Logging out user');
        await authService.logout();
      }

      if (!context.mounted) {
        debugPrint(
          '⚠️ NavigationHandler: Context is no longer mounted after logout',
        );
        return;
      }

      // Reset navigation stack dan pindah ke login page
      debugPrint('➡️ NavigationHandler: Navigating to login page');
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
