// Copyright 2025 The Room Reservation App Authors
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:room_reservation_mobile_app/app/core/network/api_config.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/exceptions/rate_limit_exception.dart';
import 'package:room_reservation_mobile_app/app/models/api_response.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';
import 'package:room_reservation_mobile_app/app/utils/navigation_handler.dart';

/// Callback untuk interceptor request HTTP
typedef HttpRequestInterceptor =
    Future<void> Function(
      String method,
      String url,
      Map<String, String> headers,
      dynamic body,
    );

/// Callback untuk interceptor response HTTP
typedef HttpResponseInterceptor =
    Future<void> Function(http.Response response, String method, String url);

/// [ApiClient] adalah class untuk membangun dan mengeksekusi HTTP requests.
///
/// Menyediakan fungsi-fungsi untuk:
/// - Melakukan request HTTP (GET, POST, PUT, PATCH, DELETE)
/// - Menangani response dan error
/// - Mengelola interceptor
/// - Menangani multipart request untuk upload file
/// - Logging untuk debugging
class ApiClient {
  // ------------------
  // Class properties
  // ------------------

  /// Flag untuk mengaktifkan debug logging
  static bool debugMode = false;

  /// Daftar interceptor untuk request
  static final List<HttpRequestInterceptor> _requestInterceptors = [];

  /// Daftar interceptor untuk response
  static final List<HttpResponseInterceptor> _responseInterceptors = [];

  /// Content type untuk request multipart
  static const String _contentTypeMultipart = 'multipart/form-data';

  final ApiConfig _api;
  final String _routeKey;
  final Map<String, String> _queries;
  final Map<String, String> _parameters;
  late final AuthService _authService;

  // ------------------
  // Constructors
  // ------------------

  ApiClient._(
    this._api,
    this._routeKey, {
    Map<String, String>? queries,
    Map<String, String>? parameters,
  }) : _queries = queries ?? {},
       _parameters = parameters ?? {};

  /// Factory constructor untuk membuat instance [ApiClient]
  static Future<ApiClient> create(
    String routeKey, {
    Map<String, String>? queries,
    Map<String, String>? parameters,
    ApiConfig? apiConfig,
  }) async {
    final api = apiConfig ?? ApiManager.getInstance();
    final builder = ApiClient._(
      api,
      routeKey,
      queries: queries,
      parameters: parameters,
    );

    await builder._initializeServices();
    return builder;
  }

  // ------------------
  // Interceptor management
  // ------------------

  /// Menambahkan interceptor untuk request
  static void addRequestInterceptor(HttpRequestInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
  }

  /// Menambahkan interceptor untuk response
  static void addResponseInterceptor(HttpResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
  }

  /// Menghapus semua interceptor
  static void clearInterceptors() {
    _requestInterceptors.clear();
    _responseInterceptors.clear();
  }

  // ------------------
  // URL building methods
  // ------------------

  /// Menambahkan parameter query
  ApiClient addQuery(String key, String value) {
    _queries[key] = value;
    return this;
  }

  /// Menambahkan multiple parameter query
  ApiClient addQueries(Map<String, String> queries) {
    _queries.addAll(queries);
    return this;
  }

  /// Menambahkan parameter path
  ApiClient addParameter(String key, String value) {
    _parameters[key] = value;
    return this;
  }

  /// Menambahkan multiple parameter path
  ApiClient addParameters(Map<String, String> parameters) {
    _parameters.addAll(parameters);
    return this;
  }

  /// Membangun URL lengkap dengan parameter
  String buildUrl() {
    try {
      String route = _api.getRoute(_routeKey);

      // Replace path parameters
      if (_parameters.isNotEmpty) {
        for (final entry in _parameters.entries) {
          route = route.replaceAll(':${entry.key}', entry.value);
        }
      }

      String url = '${_api.baseUrl}/$route';

      // Add query parameters
      if (_queries.isNotEmpty) {
        final queryString = _queries.entries
            .map(
              (e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
            )
            .join('&');
        url += '?$queryString';
      }

      return url;
    } catch (e) {
      throw ArgumentError('Gagal membangun URL: ${e.toString()}');
    }
  }

  // ------------------
  // Public HTTP methods
  // ------------------

  /// Melakukan GET request dengan error handling
  Future<T> get<T>({
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      request: () => rawGet<T>(
        fromJson: fromJson,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
      ),
      errorMessage: errorMessage,
      requiresAuth: requiresAuth,
    );
  }

  /// Melakukan POST request dengan error handling
  Future<T> post<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      request: () => rawPost<T>(
        body: body,
        fromJson: fromJson,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
      ),
      errorMessage: errorMessage,
      requiresAuth: requiresAuth,
    );
  }

  /// Melakukan PUT request dengan error handling
  Future<T> put<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      request: () => rawPut<T>(
        body: body,
        fromJson: fromJson,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
      ),
      errorMessage: errorMessage,
      requiresAuth: requiresAuth,
    );
  }

  /// Melakukan PATCH request dengan error handling
  Future<T> patch<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      request: () => rawPatch<T>(
        body: body,
        fromJson: fromJson,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
      ),
      errorMessage: errorMessage,
      requiresAuth: requiresAuth,
    );
  }

  /// Melakukan DELETE request dengan error handling
  Future<T> delete<T>({
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      request: () => rawDelete<T>(
        fromJson: fromJson,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
      ),
      errorMessage: errorMessage,
      requiresAuth: requiresAuth,
    );
  }

  /// Melakukan POST request multipart untuk upload file
  Future<T> postMultipart<T>({
    required Map<String, dynamic> fields,
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    return _handleRequest<T>(
      request: () => rawPost<T>(
        body: fields,
        fromJson: fromJson,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: {'Content-Type': _contentTypeMultipart},
      ),
      errorMessage: errorMessage,
      requiresAuth: requiresAuth,
    );
  }

  // ------------------
  // Private HTTP methods
  // ------------------

  /// Raw GET request implementation
  Future<ApiResponse<T>> rawGet<T>({
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _makeRequest<T>(
      method: 'GET',
      fromJson: fromJson,
      requiresAuth: requiresAuth,
      timeout: timeout,
      additionalHeaders: headers,
    );
  }

  /// Raw POST request implementation
  Future<ApiResponse<T>> rawPost<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _makeRequest<T>(
      method: 'POST',
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
      timeout: timeout,
      additionalHeaders: headers,
    );
  }

  /// Raw PUT request implementation
  Future<ApiResponse<T>> rawPut<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _makeRequest<T>(
      method: 'PUT',
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
      timeout: timeout,
      additionalHeaders: headers,
    );
  }

  /// Raw PATCH request implementation
  Future<ApiResponse<T>> rawPatch<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _makeRequest<T>(
      method: 'PATCH',
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
      timeout: timeout,
      additionalHeaders: headers,
    );
  }

  /// Raw DELETE request implementation
  Future<ApiResponse<T>> rawDelete<T>({
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _makeRequest<T>(
      method: 'DELETE',
      fromJson: fromJson,
      requiresAuth: requiresAuth,
      timeout: timeout,
      additionalHeaders: headers,
    );
  }

  // ------------------
  // Request handling methods
  // ------------------

  /// Initialize required services
  Future<void> _initializeServices() async {
    _authService = await AuthService.getInstance();
    _responseInterceptors.clear();

    // Add response interceptor to handle token expired
    addResponseInterceptor((response, method, url) async {
      if (response.statusCode == 401) {
        debugPrint('🔐 Interceptor: Received 401 Unauthorized from $url');

        try {
          // Cek apakah refresh token masih valid
          if (!_authService.isRefreshTokenExpired()) {
            debugPrint('🔄 Interceptor: Attempting to refresh token...');
            final refreshSuccess = await _authService.refreshTokenIfNeeded();

            // Jika refresh gagal, arahkan ke login
            if (!refreshSuccess) {
              throw ('❌ Interceptor: Token refresh failed, navigating to login page');
            } else {
              debugPrint('✅ Interceptor: Token successfully refreshed');
            }
          } else {
            // Refresh token sudah expired, langsung logout
            throw ('⏰ Interceptor: Refresh token expired, logging out');
          }
        } catch (e) {
          debugPrint('$e');

          await _authService.logout();
          NavigationHandler.handleUnauthorized();
        }
      }
    });
  }

  /// Execute HTTP request with common configuration
  Future<http.Response> _executeRequest({
    required Uri uri,
    required String method,
    required Map<String, String> headers,
    required Duration timeout,
    dynamic body,
  }) async {
    // Execute request interceptors
    for (final interceptor in _requestInterceptors) {
      await interceptor(method, uri.toString(), headers, body);
    }

    final isMultipart = headers['Content-Type'] == _contentTypeMultipart;

    if (isMultipart && body is Map<String, dynamic>) {
      return await _executeMultipartRequest(
        uri: uri,
        method: method,
        headers: headers,
        timeout: timeout,
        fields: body,
      );
    }

    return await _executeStandardRequest(
      uri: uri,
      method: method,
      headers: headers,
      timeout: timeout,
      body: body,
    );
  }

  /// Execute multipart request for file uploads
  Future<http.Response> _executeMultipartRequest({
    required Uri uri,
    required String method,
    required Map<String, String> headers,
    required Duration timeout,
    required Map<String, dynamic> fields,
  }) async {
    final request = http.MultipartRequest(method, uri);
    request.headers.addAll(headers);

    // Add fields and files
    for (final entry in fields.entries) {
      if (entry.value is File) {
        final file = entry.value as File;
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, file.path),
        );
      } else {
        request.fields[entry.key] = entry.value.toString();
      }
    }

    final streamedResponse = await request.send().timeout(timeout);
    return await http.Response.fromStream(streamedResponse);
  }

  /// Execute standard request
  Future<http.Response> _executeStandardRequest({
    required Uri uri,
    required String method,
    required Map<String, String> headers,
    required Duration timeout,
    dynamic body,
  }) async {
    final bodyString = body != null ? json.encode(body) : null;

    final request = http.Request(method, uri)
      ..headers.addAll(headers)
      ..persistentConnection = true;

    if (bodyString != null && method != 'GET') {
      request.body = bodyString;
    }

    final streamedResponse = await http.Client().send(request).timeout(timeout);

    final response = await http.Response.fromStream(streamedResponse);

    // Execute response interceptors
    for (final interceptor in _responseInterceptors) {
      await interceptor(response, method, uri.toString());
    }

    return response;
  }

  /// Melakukan HTTP request dengan handling yang konsisten
  Future<ApiResponse<T>> _makeRequest<T>({
    required String method,
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? additionalHeaders,
  }) async {
    final url = buildUrl();
    final requestTimeout = timeout ?? const Duration(seconds: 30);
    final uri = Uri.parse(url);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add custom headers if provided
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    // Add authorization header if required
    if (requiresAuth) {
      try {
        // Ensure token validity before adding to headers
        // This triggers the token refresh if needed
        final isValid = await _authService.ensureValidToken();

        if (!isValid) {
          debugPrint(
            '🚫 _makeRequest: Token not valid, cannot proceed with request',
          );

          // Check if we should attempt navigation to login
          if (_authService.isRefreshTokenExpired()) {
            debugPrint(
              '🔄 _makeRequest: Refresh token expired, handling unauthorized',
            );

            await _authService.logout();
            NavigationHandler.handleUnauthorized();
          }

          throw UnauthorizedException(
            'Token tidak valid dan tidak dapat diperbarui',
          );
        }

        final token = _authService.getAccessToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        } else {
          debugPrint(
            '🔑 _makeRequest: No token found after ensureValidToken returned true',
          );
          throw UnauthorizedException('Token tidak ditemukan');
        }
      } catch (e) {
        debugPrint(
          '⚠️ _makeRequest: Error ensuring valid token: ${e.toString()}',
        );

        if (e is UnauthorizedException) {
          // Let it propagate
          rethrow;
        }

        // For other errors, wrap in UnauthorizedException
        throw UnauthorizedException(
          'Gagal memverifikasi token: ${e.toString()}',
        );
      }
    }

    // Log request for debug
    _logRequest(method, url, headers, body);

    try {
      final response = await _executeRequest(
        uri: uri,
        method: method,
        headers: headers,
        timeout: requestTimeout,
        body: body,
      );

      // Log response for debug
      _logResponse(response, uri);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      throw NetworkException('Tidak dapat terhubung ke server');
    } on HttpException catch (e) {
      throw NetworkException('Terjadi kesalahan jaringan: ${e.message}');
    } on FormatException {
      throw ParseException('Response tidak valid dari server');
    } catch (e) {
      throw ServerException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Handle HTTP response dan convert ke ApiResponse
  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) async {
    final statusCode = response.statusCode;
    final contentType = response.headers['content-type'] ?? '';

    // Handle different response types
    if (contentType.contains('application/json')) {
      // Handle JSON response
      // Handle JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        if (statusCode >= 200 && statusCode < 300) {
          return ApiResponse<T>(data: null, message: 'Request berhasil');
        }

        throw ParseException(
          'Response tidak valid dari server: ${e.toString()}',
        );
      }

      // Handle success responses (200-299)
      if (statusCode >= 200 && statusCode < 300) {
        try {
          return ApiResponse<T>.fromJson(responseData, fromJson);
        } catch (e) {
          throw ParseException('Gagal mengurai response data: ${e.toString()}');
        }
      }

      // Handle error responses
      try {
        final message =
            responseData['message'] ?? 'Terjadi kesalahan pada server';

        _throwAppropriateError(statusCode, message);
      } catch (e) {
        // Fallback to basic error handling if ApiErrorResponse parsing fails
        final message =
            responseData['message'] ?? 'Terjadi kesalahan pada server';
        _throwAppropriateError(statusCode, message);
      }
    } else if (contentType.contains('text/plain')) {
      // Handle plain text response
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse<T>(
          data: response.body as T,
          message: 'Request berhasil',
        );
      }
      _throwAppropriateError(statusCode, response.body);
    } else {
      // Handle binary or other response types
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse<T>(
          data: response.bodyBytes as T,
          message: 'Request berhasil',
        );
      }
      _throwAppropriateError(
        statusCode,
        'Terjadi kesalahan dengan tipe konten: $contentType',
      );
    }

    throw ServerException('Unexpected response handling path');
  }

  /// Throws appropriate error based on status code
  void _throwAppropriateError(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        throw ValidationException(message);
      case 401:
        // Token handling is managed by the response interceptor
        // This will be called if the interceptor didn't handle it or for direct error handling
        debugPrint('🔒 _throwAppropriateError: Handling 401 Unauthorized');

        // Throw the exception before navigation to properly terminate the current request
        // Navigation will be handled separately by the interceptor
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 409:
        throw ConflictException(message);
      case 422:
        throw ValidationException(message);
      case 429:
        throw RateLimitException(message);
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException(message);
      default:
        throw ServerException(message);
    }
  }

  // ------------------
  // Logging methods
  // ------------------

  /// Log request untuk debug
  void _logRequest(
    String method,
    String url,
    Map<String, String> headers, [
    dynamic body,
  ]) {
    if (!debugMode) return;

    final buffer = StringBuffer()
      ..writeln('\n🔍 API Request:')
      ..write('curl -X $method');

    // Add headers
    headers.forEach((key, value) {
      buffer.write(" -H '$key: $value'");
    });

    // Add request body if exists
    if (body != null) {
      final jsonBody = json.encode(body);
      buffer.write(" -d '$jsonBody'");
    }

    // Add URL
    buffer.write(" '$url'");

    debugPrint(buffer.toString());
  }

  /// Log response untuk debug
  void _logResponse(http.Response response, Uri uri) {
    if (!debugMode) return;

    final buffer = StringBuffer()
      ..writeln('\n📡 API Response dari ${uri.toString()}:')
      ..writeln('Status: ${response.statusCode}')
      ..writeln('Body: ${response.body}');

    debugPrint(buffer.toString());
  }

  /// Wrapper untuk request dengan error handling
  Future<T> _handleRequest<T>({
    required Future<ApiResponse<T>> Function() request,
    String? errorMessage,
    bool requiresAuth = true,
  }) async {
    try {
      // Validasi dan refresh token secara proaktif
      if (requiresAuth) {
        // Menggunakan ensureValidToken yang lebih robust
        final isValid = await _authService.ensureValidToken();

        if (!isValid) {
          debugPrint('⚠️ _handleRequest: Token validation failed');

          // If refresh token is expired, navigate to login
          if (_authService.isRefreshTokenExpired()) {
            debugPrint(
              '🚪 _handleRequest: Refresh token expired, navigating to login page',
            );
            await _authService.logout();
            NavigationHandler.handleUnauthorized();
          }

          throw UnauthorizedException(
            'Token tidak valid dan tidak dapat diperbarui',
          );
        }

        debugPrint('✅ _handleRequest: Token validation successful');
      }

      // Eksekusi request
      final response = await request();

      // Handle null response
      if (response.data == null) {
        if (errorMessage != null) {
          debugPrint('⚠️ _handleRequest: Response data is null: $errorMessage');
        } else {
          debugPrint('⚠️ _handleRequest: Response data is null');
        }
        throw ServerException(errorMessage ?? 'Data response kosong');
      }

      return response.data as T;
    } on UnauthorizedException catch (e) {
      debugPrint(
        '🔒 _handleRequest: Caught UnauthorizedException: ${e.message}',
      );

      // Check if we should navigate to login page
      // Only navigate if we're not already in the process of refreshing
      if (!_authService.currentStatus.name.contains('refresh')) {
        await _authService.logout();
        NavigationHandler.handleUnauthorized();
      }

      rethrow;
    } on ValidationException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } on ConflictException {
      rethrow;
    } on RateLimitException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ _handleRequest: Unexpected error: ${e.toString()}');
      throw ServerException(
        '${errorMessage ?? 'Terjadi kesalahan'}: ${e.toString()}',
      );
    }
  }
}
