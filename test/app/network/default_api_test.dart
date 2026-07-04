import 'package:flutter_test/flutter_test.dart';
import 'package:room_reservation_mobile_app/app/core/config/app_environment.dart';
import 'package:room_reservation_mobile_app/app/network/api_config/default_api.dart';

void main() {
  group('DefaultApi', () {
    test('default mengikuti konfigurasi environment', () {
      final api = DefaultApi();

      expect(api.protocol, AppEnvironment.apiProtocol);
      expect(api.baseUrl, AppEnvironment.apiBaseUrl);
      expect(api.prefix, AppEnvironment.apiPrefix);
      expect(api.version, AppEnvironment.apiVersion);
      expect(api.url, AppEnvironment.apiUrl);
      expect(
        api.timeout,
        const Duration(seconds: AppEnvironment.apiTimeoutSeconds),
      );
    });

    test('url dirangkai dengan prefix dan versi', () {
      final api = DefaultApi(
        protocol: 'https',
        baseUrl: 'api.example.com',
        prefix: 'api',
        version: 'v2',
      );

      expect(api.url, 'https://api.example.com/api/v2');
    });

    test('url tanpa prefix dan versi', () {
      final api = DefaultApi(
        protocol: 'https',
        baseUrl: 'api.example.com',
        prefix: null,
        version: null,
      );

      expect(api.url, 'https://api.example.com');
    });

    test('buildUri mengganti path params dan menambah query', () {
      final api = DefaultApi(protocol: 'https', baseUrl: 'api.example.com');

      final uri = api.buildUri(
        moduleUrl: 'Room.detail',
        params: {'id': 'room 1'},
        queries: {'expand': 'facilities', 'empty': null},
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'api.example.com');
      expect(uri.path, '/api/v1/rooms/room%201');
      expect(uri.queryParameters, {'expand': 'facilities'});
    });

    test('buildUri memakai route mentah bila tidak terdaftar', () {
      final api = DefaultApi(protocol: 'https', baseUrl: 'api.example.com');

      final uri = api.buildUri(moduleUrl: 'custom/endpoint');

      expect(uri.path, '/api/v1/custom/endpoint');
    });
  });

  group('DefaultApiRoutes', () {
    test('menyediakan route bawaan untuk auth dan reservasi', () {
      const routes = DefaultApiRoutes();

      expect(routes.get('Auth.login'), 'auth/login');
      expect(routes.get('Auth.refresh'), 'auth/refresh');
      expect(routes.get('Auth.logout'), 'auth/logout');
      expect(routes.get('Auth.me'), 'auth/me');
      expect(routes.get('Room.list'), 'rooms');
      expect(routes.get('Reservation.detail'), 'reservations/:id');
    });

    test('copyWith menimpa dan menambah route', () {
      const routes = DefaultApiRoutes();
      final extended = routes.copyWith({
        'Auth.login': 'v2/auth/login',
        'Report.list': 'reports',
      });

      expect(extended.get('Auth.login'), 'v2/auth/login');
      expect(extended.get('Report.list'), 'reports');
      expect(extended.get('Auth.me'), 'auth/me');
    });
  });
}
