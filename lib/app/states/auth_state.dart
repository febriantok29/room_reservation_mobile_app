import 'package:room_reservation_mobile_app/app/core/config/app_feature_flags.dart';
import 'package:room_reservation_mobile_app/app/core/session/session_user_context.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';
import 'package:room_reservation_mobile_app/app/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Deprecated(
  'Gunakan authSessionProvider di lib/app/providers/auth_providers.dart untuk alur autentikasi baru berbasis Riverpod.',
)
class AuthState {
  static Profile? _currentUser;

  static Profile? get currentUser => _currentUser;

  static const _lastEmployeeIdKey = 'employeeId';
  static const _lastLoginAtKey = 'lastLoginAt';

  @Deprecated(
    'Gunakan state di authSessionProvider; method ini hanya untuk kompatibilitas legacy.',
  )
  static Future<String?> getLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastEmployeeIdKey);
  }

  @Deprecated(
    'Gunakan authSessionProvider.notifier.bootstrap(); method ini hanya untuk kompatibilitas legacy.',
  )
  static Future<bool> isLoggedIn() async {
    if (AppFeatureFlags.useApi) {
      final authService = AuthService.getInstance();
      await authService.restoreApiSession();

      if (authService.accessToken == null || authService.accessToken!.isEmpty) {
        return false;
      }

      try {
        final profile = await authService.getMyProfileFromApi();
        _currentUser = profile;
        SessionUserContext.setCurrentUser(profile);

        final prefs = await SharedPreferences.getInstance();

        if (profile.employeeId != null) {
          await prefs.setString(_lastEmployeeIdKey, profile.employeeId!);
        }

        await prefs.setInt(
          _lastLoginAtKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        return true;
      } catch (_) {
        await authService.logoutApiSession();
        return false;
      }
    }

    final prefs = await SharedPreferences.getInstance();

    final employeeId = prefs.getString(_lastEmployeeIdKey);
    final stLastLoginAt = prefs.getInt(_lastLoginAtKey);

    if (employeeId == null || stLastLoginAt == null) {
      return false;
    }

    final lastLoginAt = DateTime.fromMillisecondsSinceEpoch(stLastLoginAt);
    final now = DateTime.now();

    final difference = now.difference(lastLoginAt);

    if (difference.inDays >= 7) {
      logout();
      return false;
    }

    final profile = await UserService.getProfileByEmployeeId(employeeId);

    _currentUser = profile;

    return true;
  }

  @Deprecated(
    'Gunakan authSessionProvider.notifier.login(); method ini hanya untuk kompatibilitas legacy.',
  )
  static Future<Profile?> login({
    required String credential,
    required String password,
  }) async {
    final authService = AuthService.getInstance();

    if (AppFeatureFlags.useApi) {
      await authService.loginToApi(login: credential, password: password);

      final profile = await authService.getMyProfileFromApi();
      final prefs = await SharedPreferences.getInstance();

      if (profile.employeeId != null) {
        await prefs.setString(_lastEmployeeIdKey, profile.employeeId!);
      }

      await prefs.setInt(
        _lastLoginAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      _currentUser = profile;
      SessionUserContext.setCurrentUser(profile);
      return profile;
    }

    final profile = await authService.login(
      credential: credential,
      password: password,
    );

    final prefs = await SharedPreferences.getInstance();

    final employeeId = profile.employeeId;

    if (employeeId == null) {
      return null;
    }

    await prefs.setString(_lastEmployeeIdKey, employeeId);
    await prefs.setInt(_lastLoginAtKey, DateTime.now().millisecondsSinceEpoch);

    _currentUser = profile;
    SessionUserContext.setCurrentUser(profile);
    return profile;
  }

  @Deprecated(
    'Gunakan authSessionProvider.notifier.logout(); method ini hanya untuk kompatibilitas legacy.',
  )
  static Future<void> logout() async {
    if (AppFeatureFlags.useApi) {
      final authService = AuthService.getInstance();
      await authService.logoutApiSession();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastLoginAtKey);
      await prefs.remove(_lastEmployeeIdKey);

      _currentUser = null;
      SessionUserContext.clear();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginAtKey);

    if (_currentUser != null) {
      UserService.logout(_currentUser!);
    }

    _currentUser = null;
    SessionUserContext.clear();
  }
}
