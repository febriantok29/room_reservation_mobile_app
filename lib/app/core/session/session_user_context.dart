import 'package:room_reservation_mobile_app/app/models/profile.dart';

class SessionUserContext {
  SessionUserContext._();

  static Profile? _currentUser;

  static Profile? get currentUser => _currentUser;

  static void setCurrentUser(Profile? profile) {
    _currentUser = profile;
  }

  static void clear() {
    _currentUser = null;
  }
}
