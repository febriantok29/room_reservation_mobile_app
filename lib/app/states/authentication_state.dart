import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/core/storage/secure_storage_service.dart';
import 'package:rapa_track_mobile_app/app/models/auth_token.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';
import 'package:rapa_track_mobile_app/app/pages/login_page.dart';
import 'package:rapa_track_mobile_app/app/services/auth_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/utils/navigation_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationState {
  static const String keySavedUsername = 'AuthRequest.SavedUsername';
  static const String keyTokenData = 'AuthRequest.TokenData';

  final int? _accessTokenTtl = 9000;
  final int? _refreshTokenTtl = 9000;

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
    await _revokeFcmToken();

    if (hasToken) {
      try {
        await RouteBuilder('Auth.logout').post();
      } catch (_) {}
    }

    await forceLogout(showExpiredDialog: false);
  }

  Future<void> _revokeFcmToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    try {
      await _service.updateFcmToken('');
    } catch (_) {}
  }

  Future<void> forceLogout({bool showExpiredDialog = true}) async {
    await clearSession();

    final navigatorState = NavigationHandler.navigatorKey.currentState;
    final context = navigatorState?.context;

    if (showExpiredDialog && context != null && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          contentPadding: const EdgeInsets.all(AppSizes.xl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppColors.error,
                size: AppSizes.iconXl,
              ),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Perlu Login Ulang',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppSizes.fontLg,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              const Text(
                'Anda telah logout otomatis. Silakan login kembali untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppSizes.fontSm),
              ),
              const SizedBox(height: AppSizes.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
