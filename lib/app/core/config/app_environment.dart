/// Konfigurasi aplikasi yang dibaca dari environment (compile-time).
///
/// Nilai diinjeksi lewat `--dart-define` atau `--dart-define-from-file`,
/// contoh:
///
/// ```sh
/// flutter run --dart-define-from-file=env/development.json
/// flutter build apk --dart-define=API_BASE_URL=api.example.com \
///   --dart-define=API_PROTOCOL=https
/// ```
///
/// Semua nilai memiliki default yang aman untuk pengembangan lokal sehingga
/// aplikasi tetap bisa dijalankan tanpa konfigurasi tambahan.
class AppEnvironment {
  const AppEnvironment._();

  /// Nama environment aktif: `development`, `staging`, atau `production`.
  static const String name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Protokol API (`http` atau `https`).
  static const String apiProtocol = String.fromEnvironment(
    'API_PROTOCOL',
    defaultValue: 'http',
  );

  /// Host (dan port) API, tanpa protokol. Contoh: `api.example.com` atau
  /// `192.168.0.34:8000`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '192.168.0.34:8000',
  );

  /// Prefix path API. Kosongkan untuk menghilangkan prefix.
  static const String apiPrefix = String.fromEnvironment(
    'API_PREFIX',
    defaultValue: 'api',
  );

  /// Versi API. Kosongkan untuk menghilangkan segmen versi.
  static const String apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );

  /// Timeout request API dalam detik.
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  /// Jika `true`, login dan data diambil dari REST API;
  /// jika `false`, aplikasi memakai Firestore secara langsung.
  static const bool useApi = bool.fromEnvironment(
    'USE_API',
    defaultValue: true,
  );

  static bool get isProduction => name == 'production';
  static bool get isDevelopment => name == 'development';

  /// URL dasar API lengkap, mis. `http://192.168.0.34:8000/api/v1`.
  static String get apiUrl {
    final buffer = StringBuffer('$apiProtocol://$apiBaseUrl');

    if (apiPrefix.isNotEmpty) {
      buffer.write('/$apiPrefix');
    }

    if (apiVersion.isNotEmpty) {
      buffer.write('/$apiVersion');
    }

    return buffer.toString();
  }
}
