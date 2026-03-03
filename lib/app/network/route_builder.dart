import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:room_reservation_mobile_app/app/core/auth/auth_token_manager.dart';
import 'package:room_reservation_mobile_app/app/network/api_config/default_api.dart';

enum HttpMethod { get, post, put, patch, delete }

extension HttpMethodX on HttpMethod {
  String get rawValue => name.toUpperCase();
}

class RouteBuilder {
  static final DefaultApi _defaultApi = DefaultApi();

  final DefaultApi _api;
  final AuthTokenManager _tokenManager;
  final String _moduleUrl;

  final Map<String, dynamic> _headers;
  final Map<String, dynamic> _params;
  final Map<String, dynamic> _queries;
  final bool _requiresAuth;
  final bool _enableAutoRefreshToken;

  RouteBuilder(
    String route, {
    DefaultApi? api,
    AuthTokenManager? tokenManager,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> params = const {},
    Map<String, dynamic> queries = const {},
    bool enableAutoRefreshToken = true,
  }) : this._internal(
         api: api ?? _defaultApi,
         tokenManager: tokenManager ?? AuthTokenManager.instance,
         route: route,
         headers: headers,
         params: params,
         queries: queries,
         requiresAuth: true,
         enableAutoRefreshToken: enableAutoRefreshToken,
       );

  RouteBuilder.noAuth(
    String route, {
    DefaultApi? api,
    AuthTokenManager? tokenManager,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> params = const {},
    Map<String, dynamic> queries = const {},
  }) : this._internal(
         api: api ?? _defaultApi,
         tokenManager: tokenManager ?? AuthTokenManager.instance,
         route: route,
         headers: headers,
         params: params,
         queries: queries,
         requiresAuth: false,
         enableAutoRefreshToken: false,
       );

  RouteBuilder._internal({
    required DefaultApi api,
    required AuthTokenManager tokenManager,
    required String route,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> params = const {},
    Map<String, dynamic> queries = const {},
    required bool requiresAuth,
    required bool enableAutoRefreshToken,
  }) : _api = api,
       _tokenManager = tokenManager,
       _moduleUrl = route,
       _headers = headers,
       _params = params,
       _queries = queries,
       _requiresAuth = requiresAuth,
       _enableAutoRefreshToken = enableAutoRefreshToken;

  static DefaultApi get defaultApi => _defaultApi;

  Uri _buildUri() {
    return _api.buildUri(
      moduleUrl: _moduleUrl,
      params: _params,
      queries: _queries,
    );
  }

  Map<String, String> _buildHeaders({
    bool includeJsonContentType = false,
    bool includeAuthorization = true,
    Map<String, String>? overrides,
  }) {
    final headers = <String, String>{
      ..._api.defaultHeaders,
      ..._headers.map((key, value) => MapEntry(key, '$value')),
      ...?overrides,
    };

    if (includeJsonContentType) {
      headers.putIfAbsent(
        HttpHeaders.contentTypeHeader,
        () => 'application/json',
      );
    }

    if (includeAuthorization && _requiresAuth && _tokenManager.hasAccessToken) {
      headers[HttpHeaders.authorizationHeader] =
          'Bearer ${_tokenManager.accessToken}';
    }

    return headers;
  }

  dynamic _normalizeBody(dynamic body) {
    if (body == null) {
      return null;
    }

    if (body is String || body is List<int>) {
      return body;
    }

    if (body is Map || body is List) {
      return jsonEncode(body);
    }

    if (body is num || body is bool) {
      return '$body';
    }

    try {
      final jsonBody = (body as dynamic).toJson();
      return jsonEncode(jsonBody);
    } catch (_) {
      return '$body';
    }
  }

  Future<RouteResponse> _sendWithAutoRefresh(
    Future<http.Response> Function(Map<String, String> headers) sender,
  ) async {
    await _tokenManager.ensureLoaded();

    var response = await sender(_buildHeaders(includeJsonContentType: false));

    final shouldRetryUnauthorized =
        response.statusCode == HttpStatus.unauthorized &&
        _requiresAuth &&
        _enableAutoRefreshToken;

    if (!shouldRetryUnauthorized) {
      return RouteResponse.fromHttpResponse(response);
    }

    final refreshed = await _tokenManager.refreshAccessToken();
    if (!refreshed) {
      return RouteResponse.fromHttpResponse(response);
    }

    response = await sender(_buildHeaders(includeJsonContentType: false));

    return RouteResponse.fromHttpResponse(response);
  }

  Future<RouteResponse> _jsonRequest({
    required HttpMethod method,
    dynamic body,
  }) async {
    final uri = _buildUri();

    return _sendWithAutoRefresh((headers) async {
      final requestHeaders = _buildHeaders(
        includeJsonContentType: body != null,
        overrides: headers,
      );

      late http.Response response;

      switch (method) {
        case HttpMethod.get:
          response = await _api.client
              .get(uri, headers: requestHeaders)
              .timeout(_api.timeout);
          break;
        case HttpMethod.post:
          response = await _api.client
              .post(uri, headers: requestHeaders, body: _normalizeBody(body))
              .timeout(_api.timeout);
          break;
        case HttpMethod.put:
          response = await _api.client
              .put(uri, headers: requestHeaders, body: _normalizeBody(body))
              .timeout(_api.timeout);
          break;
        case HttpMethod.patch:
          response = await _api.client
              .patch(uri, headers: requestHeaders, body: _normalizeBody(body))
              .timeout(_api.timeout);
          break;
        case HttpMethod.delete:
          response = await _api.client
              .delete(uri, headers: requestHeaders, body: _normalizeBody(body))
              .timeout(_api.timeout);
          break;
      }

      return response;
    });
  }

  Future<RouteResponse> get() async => _jsonRequest(method: HttpMethod.get);

  Future<RouteResponse> post(dynamic body) async =>
      _jsonRequest(method: HttpMethod.post, body: body);

  Future<RouteResponse> put(dynamic body) async =>
      _jsonRequest(method: HttpMethod.put, body: body);

  Future<RouteResponse> patch(dynamic body) async =>
      _jsonRequest(method: HttpMethod.patch, body: body);

  Future<RouteResponse> delete([dynamic body]) async =>
      _jsonRequest(method: HttpMethod.delete, body: body);

  Future<RouteResponse> postMultipart({
    Map<String, String> fields = const {},
    List<MultipartFileData> files = const [],
  }) async {
    return _multipartRequest(
      method: HttpMethod.post,
      fields: fields,
      files: files,
    );
  }

  Future<RouteResponse> putMultipart({
    Map<String, String> fields = const {},
    List<MultipartFileData> files = const [],
  }) async {
    return _multipartRequest(
      method: HttpMethod.put,
      fields: fields,
      files: files,
    );
  }

  Future<RouteResponse> patchMultipart({
    Map<String, String> fields = const {},
    List<MultipartFileData> files = const [],
  }) async {
    return _multipartRequest(
      method: HttpMethod.patch,
      fields: fields,
      files: files,
    );
  }

  Future<RouteResponse> _multipartRequest({
    required HttpMethod method,
    required Map<String, String> fields,
    required List<MultipartFileData> files,
  }) async {
    final uri = _buildUri();

    return _sendWithAutoRefresh((headers) async {
      final request = http.MultipartRequest(method.rawValue, uri);
      request.headers.addAll(
        _buildHeaders(includeAuthorization: true, overrides: headers)
          ..remove(HttpHeaders.contentTypeHeader),
      );

      request.fields.addAll(fields);

      for (final file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            file.field,
            file.filePath,
            filename: file.fileName,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(_api.timeout);
      return http.Response.fromStream(streamedResponse);
    });
  }
}

class MultipartFileData {
  final String field;
  final String filePath;
  final String? fileName;

  const MultipartFileData({
    required this.field,
    required this.filePath,
    this.fileName,
  });
}

class RouteResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String rawBody;
  final dynamic data;

  const RouteResponse({
    required this.statusCode,
    required this.headers,
    required this.rawBody,
    required this.data,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  factory RouteResponse.fromHttpResponse(http.Response response) {
    return RouteResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      rawBody: response.body,
      data: _tryDecodeJson(response.body),
    );
  }

  static dynamic _tryDecodeJson(String source) {
    if (source.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(source);
    } catch (_) {
      return source;
    }
  }
}
