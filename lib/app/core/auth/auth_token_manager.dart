import 'dart:async';

import 'package:room_reservation_mobile_app/app/core/storage/secure_storage_service.dart';

class AuthTokenData {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthTokenData({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });
}

class AuthTokenManager {
  AuthTokenManager._();

  static final AuthTokenManager instance = AuthTokenManager._();

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _expiresAtKey = 'auth.expires_at';

  final SecureStorageService _storage = SecureStorageService();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  bool _isLoaded = false;
  Completer<bool>? _refreshCompleter;

  Future<AuthTokenData?> Function(String refreshToken)? _refreshHandler;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get expiresAt => _expiresAt;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> ensureLoaded() async {
    if (_isLoaded) {
      return;
    }

    _accessToken = await _storage.read(_accessTokenKey);
    _refreshToken = await _storage.read(_refreshTokenKey);

    final rawExpiresAt = await _storage.read(_expiresAtKey);
    _expiresAt = rawExpiresAt == null ? null : DateTime.tryParse(rawExpiresAt);

    _isLoaded = true;
  }

  void configureRefreshHandler(
    Future<AuthTokenData?> Function(String refreshToken)? callback,
  ) {
    _refreshHandler = callback;
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    int? expiresInSeconds,
  }) async {
    _accessToken = accessToken;

    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }

    _expiresAt = expiresInSeconds == null
        ? null
        : DateTime.now().add(Duration(seconds: expiresInSeconds));

    await _storage.write(_accessTokenKey, _accessToken!);

    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await _storage.write(_refreshTokenKey, _refreshToken!);
    }

    if (_expiresAt != null) {
      await _storage.write(_expiresAtKey, _expiresAt!.toIso8601String());
    } else {
      await _storage.delete(_expiresAtKey);
    }

    _isLoaded = true;
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _isLoaded = true;

    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
    await _storage.delete(_expiresAtKey);
  }

  Future<bool> refreshAccessToken() async {
    await ensureLoaded();

    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    if (_refreshHandler == null ||
        _refreshToken == null ||
        _refreshToken!.isEmpty) {
      return false;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshed = await _refreshHandler!.call(_refreshToken!);

      if (refreshed == null || refreshed.accessToken.isEmpty) {
        await clear();
        _refreshCompleter!.complete(false);
        return false;
      }

      await saveTokens(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken ?? _refreshToken,
        expiresInSeconds: refreshed.expiresAt?.difference(DateTime.now()).inSeconds,
      );

      _refreshCompleter!.complete(true);
      return true;
    } catch (_) {
      await clear();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
