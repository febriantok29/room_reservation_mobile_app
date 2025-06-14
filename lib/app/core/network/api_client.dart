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
  Future<ApiResponse<T>> get<T>({
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      fromJson: fromJson,
      request: () => rawGet(
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
        errorMessage: errorMessage,
      ),
    );
  }

  /// Melakukan POST request dengan error handling
  Future<ApiResponse<T>> post<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      fromJson: fromJson,
      request: () => rawPost(
        body: body,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
        errorMessage: errorMessage,
      ),
    );
  }

  /// Melakukan PUT request dengan error handling
  Future<ApiResponse<T>> put<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      fromJson: fromJson,
      request: () => rawPut(
        body: body,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
        errorMessage: errorMessage,
      ),
    );
  }

  /// Melakukan PATCH request dengan error handling
  Future<ApiResponse<T>> patch<T>({
    dynamic body,
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      fromJson: fromJson,

      request: () => rawPatch(
        body: body,
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
        errorMessage: errorMessage,
      ),
    );
  }

  /// Melakukan DELETE request dengan error handling
  Future<ApiResponse<T>> delete<T>({
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    return _handleRequest<T>(
      fromJson: fromJson,
      request: () => rawDelete(
        requiresAuth: requiresAuth,
        timeout: timeout,
        headers: headers,
        errorMessage: errorMessage,
      ),
    );
  }

  /// Melakukan POST request multipart untuk upload file
  Future<T?> postMultipart<T>({
    required Map<String, dynamic> fields,
    T Function(dynamic)? fromJson,
    String? errorMessage,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final response = await rawPost(
      body: fields,
      requiresAuth: requiresAuth,
      timeout: timeout,
      errorMessage: errorMessage,
      headers: {'Content-Type': _contentTypeMultipart},
    );

    if (response == null) {
      return null;
    }

    if (fromJson != null) {
      final decodedResponse = json.decode(response);

      return fromJson(decodedResponse);
    }

    if (response is T) {
      return response;
    }

    throw ParseException('Response tidak sesuai dengan tipe yang diharapkan');
  }

  // ------------------
  // Private HTTP methods
  // ------------------

  /// Raw GET request implementation
  Future<dynamic> rawGet({
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? headers,
    String? errorMessage,
  }) async {
    return _makeRequest(
      method: 'GET',
      requiresAuth: requiresAuth,
      timeout: timeout,
      additionalHeaders: headers,
      errorMessage: errorMessage,
    );
  }

  /// Raw POST request implementation
  Future<dynamic> rawPost({
    dynamic body,
    bool requiresAuth = true,
    Duration? timeout,
    String? errorMessage,
    Map<String, String>? headers,
  }) async {
    return _makeRequest(
      method: 'POST',
      body: body,
      requiresAuth: requiresAuth,
      timeout: timeout,
      errorMessage: errorMessage,
      additionalHeaders: headers,
    );
  }

  /// Raw PUT request implementation
  Future<dynamic> rawPut({
    dynamic body,
    bool requiresAuth = true,
    Duration? timeout,
    String? errorMessage,
    Map<String, String>? headers,
  }) async {
    return _makeRequest(
      method: 'PUT',
      body: body,
      requiresAuth: requiresAuth,
      timeout: timeout,
      errorMessage: errorMessage,
      additionalHeaders: headers,
    );
  }

  /// Raw PATCH request implementation
  Future<dynamic> rawPatch({
    dynamic body,
    bool requiresAuth = true,
    Duration? timeout,
    String? errorMessage,
    Map<String, String>? headers,
  }) async {
    return _makeRequest(
      method: 'PATCH',
      body: body,
      requiresAuth: requiresAuth,
      timeout: timeout,
      errorMessage: errorMessage,
      additionalHeaders: headers,
    );
  }

  /// Raw DELETE request implementation
  Future<dynamic> rawDelete({
    bool requiresAuth = true,
    Duration? timeout,
    String? errorMessage,
    Map<String, String>? headers,
  }) async {
    return _makeRequest(
      method: 'DELETE',
      requiresAuth: requiresAuth,
      timeout: timeout,
      errorMessage: errorMessage,
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
        try {
          // Cek apakah refresh token masih valid
          if (!_authService.isRefreshTokenExpired()) {
            final refreshSuccess = await _authService.refreshTokenIfNeeded();

            // Jika refresh gagal, arahkan ke login
            if (!refreshSuccess) {
              throw ('❌ Interceptor: Token refresh failed, navigating to login page');
            }
          } else {
            // Refresh token sudah expired, langsung logout
            throw ('⏰ Interceptor: Refresh token expired, logging out');
          }
        } catch (_) {
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

  Future<dynamic> _makeRequest({
    required String method,
    dynamic body,
    bool requiresAuth = true,
    Duration? timeout,
    Map<String, String>? additionalHeaders,
    String? errorMessage,
  }) async {
    final url = buildUrl();
    final requestTimeout = timeout ?? const Duration(seconds: 30);
    final uri = Uri.parse(url);

    final headers = <String, String>{};

    if (body != null && body is Map<String, dynamic>) {
      headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
    }

    if (additionalHeaders != null && additionalHeaders.isNotEmpty) {
      headers.addAll(additionalHeaders);
    }

    if (requiresAuth) {
      try {
        final isValid = await _authService.ensureValidToken();

        if (!isValid) {
          if (_authService.isRefreshTokenExpired()) {
            await _authService.logout();
            NavigationHandler.handleUnauthorized();
          }

          throw UnauthorizedException(
            'Akses ditolak, silakan login kembali dan coba lagi',
          );
        }

        final token = _authService.getAccessToken();
        if (token == null) {
          throw UnauthorizedException('Akses ditolak, silakan login kembali');
        }

        headers['Authorization'] = 'Bearer $token';
      } catch (e) {
        if (e is UnauthorizedException) {
          rethrow;
        }

        throw UnauthorizedException('Gagal memeriksa akses: $e');
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

      _logResponse(response, uri);

      return _handleResponse(response, errorMessage);
    } on SocketException {
      throw NetworkException('Tidak dapat terhubung ke server');
    } on HttpException catch (e) {
      throw NetworkException('Terjadi kesalahan jaringan: ${e.message}');
    } on FormatException {
      throw ParseException('Response tidak valid dari server');
    } catch (_) {
      rethrow;
    }
  }

  /// Handle HTTP response dan convert ke ApiResponse
  Future<dynamic> _handleResponse(
    http.Response response,
    String? errorMessage,
  ) async {
    final statusCode = response.statusCode;
    final rawResponseBody = response.body;

    if (statusCode < 400) {
      return rawResponseBody;
    }

    errorMessage ??=
        'Terjadi kesalahan saat memproses permintaan, silakan coba lagi, atau hubungi administrator jika masalah berlanjut';

    Map<String, dynamic>? responseBody;

    try {
      responseBody = json.decode(rawResponseBody);
    } catch (_) {}

    errorMessage =
        responseBody?['message'] ??
        responseBody?['error'] ??
        responseBody?['errorMessage'] ??
        response.reasonPhrase ??
        'Maaf, permintaan tidak dapat diproses';

    _throwAppropriateError(statusCode, '$errorMessage');

    throw ServerException('Maaf, permintaan tidak dapat diproses');
  }

  /// Throws appropriate error based on status code
  void _throwAppropriateError(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        throw ValidationException(message);
      case 401:
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
  Future<ApiResponse<T>> _handleRequest<T>({
    required Future<dynamic> Function() request,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await request();

    Map<String, dynamic>? responseBody;

    try {
      responseBody = json.decode(response);
    } catch (_) {
      if (response is! T) {
        throw ParseException('Maaf, format yang diterima tidak sesuai');
      }

      return ApiResponse<T>(data: response, message: 'Request berhasil');
    }

    if (responseBody == null || responseBody.isEmpty) {
      throw ParseException('Maaf, format yang diterima tidak sesuai');
    }

    return ApiResponse<T>.fromJson(responseBody, fromJson);
  }
}
