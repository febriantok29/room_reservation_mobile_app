import 'dart:io';

import 'package:http/http.dart' as http;

class DefaultApi {
  final String protocol;
  final String baseUrl;
  final String? prefix;
  final String? version;
  final DefaultApiRoutes _routes;
  final http.Client _client;
  final Duration timeout;
  final Map<String, String> defaultHeaders;

  DefaultApi({
    this.protocol = 'http',
    this.baseUrl = '192.168.0.34:8000',
    this.prefix = 'api',
    this.version = 'v1',
    DefaultApiRoutes routes = const DefaultApiRoutes(),
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    Map<String, String> defaultHeaders = const {
      HttpHeaders.acceptHeader: 'application/json',
    },
  }) : _routes = routes,
       _client = client ?? http.Client(),
       defaultHeaders = Map<String, String>.unmodifiable(defaultHeaders);

  String get url {
    String currentUrl = '$protocol://$baseUrl';

    if (prefix != null && prefix!.isNotEmpty) {
      currentUrl += '/$prefix';
    }

    if (version != null && version!.isNotEmpty) {
      currentUrl += '/$version';
    }

    return currentUrl;
  }

  http.Client get client => _client;
  DefaultApiRoutes get routes => _routes;

  Uri buildUri({
    required String moduleUrl,
    Map<String, dynamic> params = const {},
    Map<String, dynamic> queries = const {},
  }) {
    final mappedRoute = routes.get(moduleUrl);
    var endpoint = mappedRoute;

    if (params.isNotEmpty) {
      params.forEach((key, value) {
        endpoint = endpoint.replaceAll(':$key', Uri.encodeComponent('$value'));
      });
    }

    final normalized = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    final fullPath =
        '${url.endsWith('/') ? url.substring(0, url.length - 1) : url}/$normalized';

    final queryParams = <String, String>{};
    queries.forEach((key, value) {
      if (value == null) {
        return;
      }

      queryParams[key] = '$value';
    });

    return Uri.parse(
      fullPath,
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
  }
}

class DefaultApiRoutes {
  const DefaultApiRoutes({Map<String, String> routes = _defaultRoutes})
    : _routes = routes;

  static const Map<String, String> _defaultRoutes = {
    'Auth.login': 'auth/login',
    'Auth.refresh': 'auth/refresh',
    'Auth.logout': 'auth/logout',
    'Auth.me': 'auth/me',
    'Room.list': 'rooms',
    'Room.detail': 'rooms/:id',
    'Reservation.list': 'reservations',
    'Reservation.detail': 'reservations/:id',
  };

  final Map<String, String> _routes;

  String get(String route) => _routes[route] ?? route;

  DefaultApiRoutes copyWith(Map<String, String> routes) {
    return DefaultApiRoutes(routes: {..._routes, ...routes});
  }
}
