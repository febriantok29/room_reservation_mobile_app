import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/core/storage/secure_storage_service.dart';
import 'package:room_reservation_mobile_app/app/models/auth_token.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';
import 'package:room_reservation_mobile_app/app/pages/login_page.dart';
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

  bool get isLoggedIn => _user != null && _token != null;
  Profile? get user => _user;
  String? get accessToken => _token?.accessToken;
  DateTime? get tokenExpiresAt => _token?.expiresAt;
  bool get hasToken => _token != null;

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
    final router = RouteBuilder.noAuth('Auth.login');

    final payload = <String, dynamic>{
      'login': credential,
      'password': password,
    };

    if (_accessTokenTtl != null && _refreshTokenTtl != null) {
      payload['is_debug'] = true;
      payload['access_token_ttl'] = _accessTokenTtl;
      payload['refresh_token_ttl'] = _refreshTokenTtl;
    }

    final response = await router.post(body: payload);

    if (response == null || response is! Map<String, dynamic>) {
      throw 'Format respons tidak valid';
    }

    final data = response['data'] ?? response;
    if (data['access_token'] == null) {
      throw data['message'] ?? 'Login gagal, periksa kembali kredensial Anda.';
    }

    _token = AuthToken.fromJson(data);
    await _secureStorage.writeJson(keyTokenData, _token!.toJson());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySavedUsername, credential);

    await refreshUser();
    return _user != null;
  }

  Future<void> refreshUser() async {
    if (!hasToken) return;

    final router = RouteBuilder('Auth.me');
    final response = await router.get();

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      _user = Profile.fromJson(data);
    }
  }

  Future<void>? _refreshFuture;

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
    final router = RouteBuilder.noAuth('Auth.refresh');

    final payload = <String, dynamic>{'refresh_token': _token!.refreshToken};

    if (_accessTokenTtl != null && _refreshTokenTtl != null) {
      payload['is_debug'] = true;
      payload['access_token_ttl'] = _accessTokenTtl;
    }

    final response = await router.post(body: payload);

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      if (data['access_token'] != null) {
        _token = AuthToken.fromJson(data);
        await _secureStorage.writeJson(keyTokenData, _token!.toJson());
      } else {
        await clearSession();
        await forceLogout();
      }
    }
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
