import 'package:flutter_test/flutter_test.dart';
import 'package:room_reservation_mobile_app/app/core/config/app_environment.dart';
import 'package:room_reservation_mobile_app/app/core/config/app_feature_flags.dart';

void main() {
  group('AppEnvironment', () {
    test('memiliki default yang valid untuk pengembangan lokal', () {
      expect(AppEnvironment.name, isNotEmpty);
      expect(AppEnvironment.apiProtocol, anyOf('http', 'https'));
      expect(AppEnvironment.apiBaseUrl, isNotEmpty);
      expect(AppEnvironment.apiTimeoutSeconds, greaterThan(0));
    });

    test('apiUrl dirangkai dari protokol, host, prefix, dan versi', () {
      final expected = StringBuffer(
        '${AppEnvironment.apiProtocol}://${AppEnvironment.apiBaseUrl}',
      );

      if (AppEnvironment.apiPrefix.isNotEmpty) {
        expected.write('/${AppEnvironment.apiPrefix}');
      }

      if (AppEnvironment.apiVersion.isNotEmpty) {
        expected.write('/${AppEnvironment.apiVersion}');
      }

      expect(AppEnvironment.apiUrl, expected.toString());
    });

    test('flag environment konsisten dengan nama environment', () {
      expect(
        AppEnvironment.isDevelopment,
        AppEnvironment.name == 'development',
      );
      expect(AppEnvironment.isProduction, AppEnvironment.name == 'production');
    });

    test('AppFeatureFlags.useApi mengikuti environment', () {
      expect(AppFeatureFlags.useApi, AppEnvironment.useApi);
    });
  });
}
