import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';
import 'package:room_reservation_mobile_app/app/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  static Profile? _currentUser;

  static Profile? get currentUser => _currentUser;

  static const _lastEmployeeIdKey = 'employeeId';
  static const _lastLoginAtKey = 'lastLoginAt';

  static Future<String?> getLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastEmployeeIdKey);
  }

  static Future<bool> isLoggedIn() async {
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

  static Future<Profile?> login({
    required String credential,
    required String password,
  }) async {
    final authService = AuthService.getInstance();

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

    return _currentUser = profile;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginAtKey);
    _currentUser = null;
  }
}
