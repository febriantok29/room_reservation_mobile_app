// Copyright 2025 The Room Reservation App Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:room_reservation_mobile_app/app/core/network/api_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/login_response.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/refresh_token_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status autentikasi pengguna
enum AuthStatus {
  /// Pengguna belum terautentikasi
  unauthenticated,

  /// Pengguna sudah terautentikasi
  authenticated,

  /// Token sedang di-refresh
  refreshing,

  /// Terjadi error saat autentikasi
  error,
}

/// Event untuk perubahan status autentikasi
class AuthStateChange {
  final AuthStatus status;
  final String? message;
  final dynamic error;

  AuthStateChange(this.status, {this.message, this.error});
}

/// Service untuk menangani autentikasi pengguna
class AuthService {
  /// Toleransi waktu sebelum token benar-benar expired (dalam detik)
  static const int _tokenExpiryTolerance = 4;

  /// Key untuk menyimpan data di SharedPreferences
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _accessTokenExpiresAtKey = 'access_token_expires_at';
  static const String _refreshTokenExpiresAtKey = 'refresh_token_expires_at';

  /// Singleton instance
  static AuthService? _instance;

  /// SharedPreferences instance
  late SharedPreferences _prefs;

  /// Stream controller untuk status autentikasi
  final _authStateController = StreamController<AuthStateChange>.broadcast();

  /// Stream untuk mendengarkan perubahan status autentikasi
  Stream<AuthStateChange> get authStateChanges => _authStateController.stream;

  /// Status autentikasi saat ini
  AuthStatus _currentStatus = AuthStatus.unauthenticated;
  AuthStatus get currentStatus => _currentStatus;

  /// Private constructor
  AuthService._();

  /// Factory untuk mendapatkan instance AuthService
  static Future<AuthService> getInstance() async {
    if (_instance == null) {
      _instance = AuthService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Inisialisasi service
  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _updateAuthStatus();
  }

  /// Update status autentikasi dan broadcast ke listeners
  void _updateAuthStatus([String? message, dynamic error]) {
    final newStatus = _determineAuthStatus();

    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _authStateController.add(
        AuthStateChange(newStatus, message: message, error: error),
      );
    }
  }

  /// Menentukan status autentikasi berdasarkan kondisi saat ini
  AuthStatus _determineAuthStatus() {
    if (_isRefreshing) return AuthStatus.refreshing;
    if (!isLoggedIn()) return AuthStatus.unauthenticated;
    return AuthStatus.authenticated;
  }

  /// Menyimpan data login ke local storage
  Future<void> saveLoginData(LoginResponse loginResponse) async {
    try {
      await Future.wait([
        _prefs.setString(_accessTokenKey, loginResponse.accessToken ?? ''),
        _prefs.setString(_refreshTokenKey, loginResponse.refreshToken ?? ''),
        _prefs.setString(
          _userDataKey,
          jsonEncode(loginResponse.userData.toJson()),
        ),
        _prefs.setString(
          _accessTokenExpiresAtKey,
          loginResponse.accessTokenExpiresAt?.toIso8601String() ?? '',
        ),
        _prefs.setString(
          _refreshTokenExpiresAtKey,
          loginResponse.refreshTokenExpiresAt?.toIso8601String() ?? '',
        ),
      ]);
      _updateAuthStatus('Login berhasil');
    } catch (e) {
      _updateAuthStatus('Gagal menyimpan data login', e);
      throw StateError('Gagal menyimpan data login: ${e.toString()}');
    }
  }

  /// Menyimpan data refresh token ke local storage
  Future<void> saveRefreshTokenData(
    RefreshTokenResponse refreshResponse,
  ) async {
    try {
      await Future.wait([
        _prefs.setString(_accessTokenKey, refreshResponse.accessToken ?? ''),
        _prefs.setString(_refreshTokenKey, refreshResponse.refreshToken ?? ''),
        if (refreshResponse.accessTokenExpiresAt != null)
          _prefs.setString(
            _accessTokenExpiresAtKey,
            refreshResponse.accessTokenExpiresAt!.toIso8601String(),
          ),
        if (refreshResponse.refreshTokenExpiresAt != null)
          _prefs.setString(
            _refreshTokenExpiresAtKey,
            refreshResponse.refreshTokenExpiresAt!.toIso8601String(),
          ),
      ]);
      _updateAuthStatus('Token berhasil diperbarui');
    } catch (e) {
      _updateAuthStatus('Gagal menyimpan data refresh token', e);
      throw StateError('Gagal menyimpan data refresh token: ${e.toString()}');
    }
  }

  /// Login user dengan credential dan password
  Future<LoginResponse> login({
    required String credential,
    required String password,
  }) async {
    try {
      final builder = await ApiClient.create('Auth.Login');
      final response = await builder.post<LoginResponse>(
        body: {'credential': credential, 'password': password},
        fromJson: LoginResponse.fromJson,
        requiresAuth: false,
      );

      if (response.accessToken == null || response.refreshToken == null) {
        throw ValidationException('Token tidak valid dari server');
      }

      await saveLoginData(response);
      return response;
    } catch (e) {
      _updateAuthStatus('Login gagal', e);
      rethrow;
    }
  }

  /// Mendapatkan access token dari storage
  String? getAccessToken() {
    final token = _prefs.getString(_accessTokenKey);
    if (token?.isEmpty ?? true) return null;
    return token;
  }

  /// Mendapatkan refresh token dari storage
  String? getRefreshToken() {
    final token = _prefs.getString(_refreshTokenKey);
    if (token?.isEmpty ?? true) return null;
    return token;
  }

  /// Mendapatkan data user dari cache
  Profile? getUserData() {
    try {
      final userDataString = _prefs.getString(_userDataKey);
      if (userDataString == null || userDataString.isEmpty) return null;

      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      return Profile.fromJson(userData);
    } catch (e) {
      debugPrint('Error parsing user data: ${e.toString()}');
      return null;
    }
  }

  /// Cek apakah refresh token sudah expired
  bool isRefreshTokenExpired() {
    final token = getRefreshToken();
    final expiryString = _prefs.getString(_refreshTokenExpiresAtKey);

    if (token == null || expiryString == null) return true;

    try {
      final expiry = DateTime.parse(expiryString).toLocal();
      final now = DateTime.now();

      return now.isAfter(
        expiry.subtract(Duration(seconds: _tokenExpiryTolerance)),
      );
    } catch (e) {
      debugPrint('Error checking refresh token expiry: ${e.toString()}');
      return true;
    }
  }

  /// Cek apakah access token sudah expired
  bool isAccessTokenExpired() {
    final token = getAccessToken();
    if (token == null) return true;

    try {
      if (!JwtDecoder.isExpired(token)) {
        final expiry = JwtDecoder.getExpirationDate(token);
        final now = DateTime.now();

        if (expiry.difference(now).inSeconds > _tokenExpiryTolerance) {
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error checking access token expiry: ${e.toString()}');
      return true;
    }
  }

  /// Cek apakah user sudah login
  bool isLoggedIn() {
    final accessToken = getAccessToken();
    final refreshToken = getRefreshToken();

    if (accessToken == null || refreshToken == null) return false;
    if (isRefreshTokenExpired()) return false;

    return true;
  }

  /// Cek apakah perlu refresh token
  bool needsTokenRefresh() {
    if (!isLoggedIn()) return false;
    return isAccessTokenExpired() && !isRefreshTokenExpired();
  }

  /// Menghapus semua data authentication dari storage
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _prefs.remove(_accessTokenKey),
        _prefs.remove(_refreshTokenKey),
        _prefs.remove(_userDataKey),
        _prefs.remove(_accessTokenExpiresAtKey),
        _prefs.remove(_refreshTokenExpiresAtKey),
      ]);
      _updateAuthStatus('Data auth berhasil dihapus');
    } catch (e) {
      _updateAuthStatus('Gagal menghapus data auth', e);
      throw StateError('Gagal menghapus data auth: ${e.toString()}');
    }
  }

  /// Logout user dan hapus semua data auth
  Future<void> logout() async {
    try {
      // Coba logout ke server jika masih ada token valid
      if (isLoggedIn() && !isAccessTokenExpired()) {
        try {
          final builder = await ApiClient.create('Auth.Logout');
          await builder.post<void>(
            requiresAuth: true,
            errorMessage: 'Gagal logout dari server',
          );
        } catch (e) {
          debugPrint('Error logging out from server: ${e.toString()}');
        }
      }

      await clearAuthData();
      _updateAuthStatus('Logout berhasil');
    } catch (e) {
      _updateAuthStatus('Logout gagal', e);
      rethrow;
    }
  }

  /// Mendapatkan data user yang sedang login
  Future<Profile?> getCurrentUser({bool forceRefresh = false}) async {
    try {
      if (!isLoggedIn()) return null;

      // Gunakan cache jika ada dan tidak diminta refresh
      if (!forceRefresh) {
        final cachedUser = getUserData();
        if (cachedUser != null) return cachedUser;
      }

      // Fetch dari API
      final builder = await ApiClient.create('User.getProfile');
      final response = await builder.get<Profile>(
        fromJson: Profile.fromJson,
        requiresAuth: true,
        errorMessage: 'Gagal mengambil data user',
      );

      // Update cache
      await _prefs.setString(_userDataKey, jsonEncode(response.toJson()));
      return response;
    } catch (e) {
      debugPrint('Error getting current user: ${e.toString()}');
      // Return cached data jika gagal fetch
      return getUserData();
    }
  }

  /// Mendapatkan Bearer token untuk Authorization header
  String? getBearerToken() {
    final token = getAccessToken();
    if (token == null) return null;
    return 'Bearer $token';
  }

  /// Lock untuk mencegah multiple refresh token requests
  static bool _isRefreshing = false;
  static Future<RefreshTokenResponse?>? _refreshFuture;
  static Completer<bool>? _refreshCompleter;

  /// Refresh access token jika diperlukan
  Future<bool> refreshTokenIfNeeded() async {
    // Jangan refresh jika refresh token expired
    if (isRefreshTokenExpired()) {
      debugPrint('🔄 refreshTokenIfNeeded: Refresh token sudah kadaluarsa');
      _updateAuthStatus('Refresh token kadaluarsa');
      return false;
    }

    try {
      // Jika sudah ada proses refresh yang berjalan, tunggu hasilnya
      if (_isRefreshing && _refreshCompleter != null) {
        debugPrint(
          '⏳ refreshTokenIfNeeded: Menunggu refresh token yang sedang berjalan',
        );
        _updateAuthStatus('Menunggu refresh token yang sedang berjalan');
        return await _refreshCompleter!.future;
      }

      // Mulai proses refresh baru
      _isRefreshing = true;
      _refreshCompleter =
          Completer<bool>(); // Create new completer for this operation
      _updateAuthStatus('Memperbarui token');
      debugPrint('🔄 refreshTokenIfNeeded: Memulai refresh token baru');
      _refreshFuture = _doRefreshToken();

      final response = await _refreshFuture;
      final isSuccess = response != null && response.accessToken != null;

      // Simpan hasil dan beritahu semua yang menunggu
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(isSuccess);
      }

      if (isSuccess) {
        debugPrint('✅ refreshTokenIfNeeded: Token berhasil diperbarui');
        _updateAuthStatus('Token berhasil diperbarui');
      } else {
        debugPrint('❌ refreshTokenIfNeeded: Gagal memperbarui token');
        _updateAuthStatus('Gagal memperbarui token');
      }

      return isSuccess;
    } catch (e) {
      debugPrint(
        '⚠️ refreshTokenIfNeeded: Error saat memperbarui token: ${e.toString()}',
      );
      _updateAuthStatus('Error saat memperbarui token', e);

      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }

      return false;
    } finally {
      _isRefreshing = false;
      _refreshFuture = null;
      // Don't reset completer here to allow concurrent waiters to get the result
    }
  }

  /// Melakukan refresh token ke server
  Future<RefreshTokenResponse?> _doRefreshToken() async {
    final refreshToken = getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final builder = await ApiClient.create('Auth.Refresh');
      final response = await builder.post<RefreshTokenResponse>(
        body: {'refreshToken': refreshToken},
        fromJson: RefreshTokenResponse.fromJson,
        requiresAuth: false,
        errorMessage: 'Gagal refresh token',
      );

      if (response.accessToken == null || response.refreshToken == null) {
        throw ValidationException('Token tidak valid dari server');
      }

      // Store the new token data before returning
      await saveRefreshTokenData(response);
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Ensure token is saved
      return response;
    } catch (e) {
      debugPrint('Error refreshing token: ${e.toString()}');
      return null;
    }
  }

  /// Validate dan refresh token otomatis
  Future<bool> ensureValidToken() async {
    // Check if user is logged in
    if (!isLoggedIn()) {
      debugPrint('🔒 ensureValidToken: User tidak login');
      _updateAuthStatus('User tidak login');
      return false;
    }

    try {
      // If token will expire soon or is already expired, refresh it
      if (isAccessTokenExpired() || _isTokenNearExpiry()) {
        debugPrint(
          '⏰ ensureValidToken: Token expired atau akan expired segera, perlu refresh',
        );

        // Try to refresh token
        final refreshSuccess = await refreshTokenIfNeeded();

        // If refresh failed and refresh token is expired, we need to logout
        if (!refreshSuccess && isRefreshTokenExpired()) {
          debugPrint(
            '🚪 ensureValidToken: Refresh gagal dan refresh token expired, logout dan redirect',
          );
          await logout();
          return false;
        }

        return refreshSuccess;
      }

      debugPrint('✓ ensureValidToken: Token masih valid');
      return true;
    } catch (e) {
      debugPrint(
        '❌ ensureValidToken: Error memvalidasi token: ${e.toString()}',
      );

      // If there's an error, we should return false to be safe
      return false;
    }
  }

  /// Cek apakah token akan expired dalam waktu dekat (10 menit)
  bool _isTokenNearExpiry() {
    final token = getAccessToken();
    if (token == null) return true;

    try {
      final expiry = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      // Check if token expires in less than 10 minutes
      return expiry.difference(now).inMinutes <= 10;
    } catch (e) {
      debugPrint('Error checking token expiry: ${e.toString()}');
      return true;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _authStateController.close();
  }
}
