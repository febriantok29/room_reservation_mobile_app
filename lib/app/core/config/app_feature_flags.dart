import 'package:room_reservation_mobile_app/app/core/config/app_environment.dart';

class AppFeatureFlags {
  const AppFeatureFlags._();

  /// Dikendalikan lewat environment: `--dart-define=USE_API=false`
  /// untuk memakai Firestore langsung tanpa REST API.
  static const bool useApi = AppEnvironment.useApi;
}
