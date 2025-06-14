/// Interface untuk API configuration
abstract class ApiConfig {
  String get baseUrl;
  String getRoute(String key);
}

/// Interface untuk route provider
abstract class ApiEndpoints {
  String getRoute(String key);
  Map<String, String> get routes;
}

/// Default implementation dari API configuration
class DefaultApiConfig implements ApiConfig {
  static const String _protocol = 'http';
  static const String _host = '139.59.113.107';
  static const String _prefix = 'api';

  @override
  String get baseUrl => '$_protocol://$_host/$_prefix';

  final ApiEndpoints _endpoints;

  DefaultApiConfig({ApiEndpoints? endpoints})
    : _endpoints = endpoints ?? DefaultApiEndpoints();

  @override
  String getRoute(String key) {
    return _endpoints.getRoute(key);
  }
}

/// Default implementation dari route provider
class DefaultApiEndpoints implements ApiEndpoints {
  @override
  final Map<String, String> routes = {
    // Authentication endpoints
    'Auth.Login': 'auth/login',
    'Auth.Refresh': 'auth/refresh-token',
    'Auth.Logout': 'auth/logout',

    // Room endpoints
    'Room.getAll': 'rooms',
    'Room.getAvailable': 'rooms/available',
    'Room.getById': 'rooms/:id',

    // Reservation endpoints
    'Reservation.getAll': 'reservations',
    'Reservation.getById': 'reservations/:id',
    'Reservation.create': 'reservations',
    'Reservation.update': 'reservations/:id',
    'Reservation.delete': 'reservations/:id',

    // User endpoints
    'User.getProfile': 'users/profile',
    'User.updateProfile': 'users/profile',
    'User.changePassword': 'users/change-password',
  };

  @override
  String getRoute(String key) {
    final route = routes[key];
    if (route == null) {
      throw ArgumentError('Route dengan key "$key" tidak ditemukan');
    }
    return route;
  }
}

/// Singleton untuk mendapatkan instance API
class ApiManager {
  static ApiConfig? _instance;

  /// Mendapatkan instance API configuration
  static ApiConfig getInstance() {
    _instance ??= DefaultApiConfig();
    return _instance!;
  }

  /// Set custom API configuration (untuk testing atau environment berbeda)
  static void setInstance(ApiConfig apiConfig) {
    _instance = apiConfig;
  }

  /// Reset instance (untuk testing)
  static void resetInstance() {
    _instance = null;
  }
}
