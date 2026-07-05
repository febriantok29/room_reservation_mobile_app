import 'package:flutter/foundation.dart';
import 'package:haleyora_package/enum.dart';
import 'package:haleyora_package/haleyora_package.dart';
import 'package:http/http.dart' as http;
import 'package:rapa_track_mobile_app/app/network/api_config/default_api.dart';
import 'package:rapa_track_mobile_app/app/states/authentication_state.dart';

class RouteBuilder extends ApiClient {
  static final ApiConfig _sharedConfig = DefaultApi();
  final bool _requiresAuth;

  @override
  Duration get requestTimeout => const Duration(seconds: 15);

  RouteBuilder(
    String endpoint, {
    ApiConfig? api,
    Map<String, dynamic>? queries,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) : _requiresAuth = requiresAuth,
       super(
         config: api ?? _sharedConfig,
         endpoint: _resolveRoute(endpoint, api ?? _sharedConfig, params),
         queries: queries?.map((k, v) => MapEntry(k, v.toString())) ?? const {},
         headers: headers ?? const {},
         debugMode: kDebugMode,
       );

  factory RouteBuilder.noAuth(String endpoint, {ApiConfig? api}) {
    return RouteBuilder(endpoint, api: api, requiresAuth: false);
  }

  static String _resolveRoute(
    String endpoint,
    ApiConfig config,
    Map<String, dynamic>? params,
  ) {
    String path = endpoint;
    if (config.endpoints.routes.containsKey(endpoint)) {
      path = config.endpoints.routes[endpoint]!;
    }
    if (params != null && params.isNotEmpty) {
      params.forEach((key, value) {
        path = path.replaceAll(':$key', value.toString());
      });
    }
    return path;
  }

  @override
  Future<void> preRequest(HttpMethod method, {body}) async {
    super.addHeader('Accept', 'application/json');

    if (!_requiresAuth) return;

    final authState = AuthenticationState();

    if (authState.hasToken) {
      final expiresAt = authState.tokenExpiresAt;
      if (expiresAt != null) {
        final timeToLive = expiresAt.difference(DateTime.now()).inSeconds;

        if (timeToLive <= 15) {
          try {
            await authState.refreshToken();
          } catch (_) {
            await authState.forceLogout();
            throw 'Sesi berakhir, silakan login kembali.';
          }
        }
      }

      final token = authState.accessToken;
      if (token != null) {
        super.addHeader('Authorization', 'Bearer $token');
      }
    } else {
      await authState.forceLogout();
      throw 'Tidak ada sesi aktif, silakan login.';
    }
  }

  @override
  String? handleApiError({
    required dynamic error,
    http.Response? response,
    dynamic responseBody,
  }) {
    String responseMessage =
        'Gagal mendapat respon dari server, silakan coba beberapa saat lagi.';

    if (responseBody is Map<String, dynamic>) {
      final statusCode = response?.statusCode ?? 0;
      bool isSuccess = true;

      if (responseBody.containsKey('success')) {
        final rawIsSuccess = responseBody['success'];
        if (rawIsSuccess is bool) {
          isSuccess = rawIsSuccess;
        } else if (rawIsSuccess is num) {
          isSuccess = rawIsSuccess == 1;
        }
      }

      final errorCode = responseBody['error_code'];
      if (errorCode == 'UNAUTHORIZED' || statusCode == 401) {
        if (AuthenticationState().hasToken) {
          AuthenticationState().forceLogout();
        }
        return responseBody['message']?.toString() ?? 'Sesi telah berakhir.';
      }

      if (isSuccess && statusCode < 400) {
        return null;
      }

      if (responseBody.containsKey('message')) {
        final message = responseBody['message'];
        if (message is Map) {
          responseMessage = '${message.values.first}';
          if (message.values.first is List) {
            responseMessage = '${(message.values.first as List).first}';
          }
        } else {
          responseMessage = '$message';
        }
      }

      return responseMessage;
    }

    return responseMessage;
  }
}
