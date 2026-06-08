import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/core/storage/secure_storage_service.dart';
import 'package:room_reservation_mobile_app/app/models/auth_token.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';
import 'package:room_reservation_mobile_app/app/pages/login_page.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';
import 'package:room_reservation_mobile_app/app/utils/navigation_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationState {
  static const String keySavedUsername = 'AuthRequest.SavedUsername';
  static const String keyTokenData = 'AuthRequest.TokenData';

  final int? _accessTokenTtl = null;
  final int? _refreshTokenTtl = null;

  static AuthenticationState? _instance;

  AuthenticationState._();

  factory AuthenticationState() {
    _instance ??= AuthenticationState._();
    return _instance!;
  }

  final _secureStorage = SecureStorageService();

  Profile? _user;
  AuthToken? _token;
  Future<void>? _refreshFuture;

  bool get isLoggedIn => _user != null && _token != null;
  Profile? get user => _user;
  String? get accessToken => _token?.accessToken;
  DateTime? get tokenExpiresAt => _token?.expiresAt;
  bool get hasToken => _token != null;

  final _service = AuthService();

  Future<void> initialize() async {
    final tokenMap = await _secureStorage.readJson(keyTokenData);
    if (tokenMap != null) {
      _token = AuthToken.fromJson(tokenMap);

      if (_token!.expiresAt != null &&
          _token!.expiresAt!.difference(DateTime.now()).inSeconds <= 0) {
        await clearSession();
        return;
      }

      try {
        await refreshUser();
      } catch (_) {
        await clearSession();
      }
    }
  }

  Future<bool> login(String credential, String password) async {
    _token = await _service.login(
      credential: credential,
      password: password,
      accessTokenTtl: _accessTokenTtl,
      refreshTokenTtl: _refreshTokenTtl,
    );

    await _secureStorage.writeJson(keyTokenData, _token!.toJson());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySavedUsername, credential);

    await refreshUser();
    return _user != null;
  }

  Future<void> refreshUser() async {
    if (!hasToken) return;

    _user = await _service.getMe();
  }

  Future<void> refreshToken() async {
    if (_token?.refreshToken == null) return;

    if (_refreshFuture != null) {
      return _refreshFuture;
    }

    _refreshFuture = _doRefreshToken();
    try {
      await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _doRefreshToken() async {
    final currentRefreshToken = _token!.refreshToken;
    if (currentRefreshToken == null) {
      await clearSession();
      await forceLogout();
      return;
    }

    final refreshedToken = await _service.refreshToken(
      refreshToken: currentRefreshToken,
      accessTokenTtl: _accessTokenTtl,
      refreshTokenTtl: _refreshTokenTtl,
    );

    if (refreshedToken == null) {
      await clearSession();
      await forceLogout();
      return;
    }

    _token = refreshedToken;
    await _secureStorage.writeJson(keyTokenData, _token!.toJson());
  }

  Future<void> logout() async {
    if (hasToken) {
      try {
        await RouteBuilder('Auth.logout').post();
      } catch (_) {}
    }

    await forceLogout();
  }

  Future<void> forceLogout() async {
    await clearSession();

    final context = NavigationHandler.navigatorKey.currentState?.context;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi telah berakhir, silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Redirect ke login page
    NavigationHandler.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> clearSession() async {
    _user = null;
    _token = null;
    await _secureStorage.delete(keyTokenData);
  }
}
