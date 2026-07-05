import 'package:haleyora_package/haleyora_package.dart';

const _apiHost = String.fromEnvironment(
  'API_HOST',
  defaultValue: '192.168.100.9:8000',
);
const _apiProtocol = String.fromEnvironment(
  'API_PROTOCOL',
  defaultValue: 'http',
);

class DefaultApi extends ApiConfig {
  @override
  String get protocol => _apiProtocol;

  @override
  ApiEndpoints get endpoints => DefaultApiRoutes();

  @override
  String? get prefix => 'api';

  @override
  List<String> get hosts => [_apiHost];

  @override
  String? get version => 'v1';
}

class DefaultApiRoutes extends ApiEndpoints {
  @override
  Map<String, String> get routes => {
    'Auth.login': 'auth/login',
    'Auth.refresh': 'auth/refresh',
    'Auth.logout': 'auth/logout',
    'Auth.me': 'auth/me',
    'Auth.updateFcmToken': 'auth/fcm-token',
    'Room.list': 'rooms',
    'Room.available': 'rooms/available',
    'Room.detail': 'rooms/:id',
    'Room.create': 'rooms',
    'Room.update': 'rooms/:id',
    'Room.delete': 'rooms/:id',
    'Room.availability': 'rooms/:id/availability',
    'Facility.list': 'facilities',
    'Facility.detail': 'facilities/:id',
    'Facility.create': 'facilities',
    'Facility.update': 'facilities/:id',
    'Facility.delete': 'facilities/:id',
    'Reservation.list': 'reservations',
    'Reservation.calendar': 'reservations/calendar',
    'Reservation.create': 'reservations',
    'Reservation.detail': 'reservations/:id',
    'Reservation.update': 'reservations/:id',
    'Reservation.cancel': 'reservations/:id/cancel',
    'Reservation.approve': 'reservations/:id/approve',
    'Reservation.reject': 'reservations/:id/reject',
    'Reservation.complete': 'reservations/:id/complete',
    'User.list': 'users',
    'Complaint.list': 'complaints',
    'Complaint.detail': 'complaints/:id',
    'Complaint.create': 'complaints',
    'Complaint.updateStatus': 'complaints/:id/status',
    'Notification.list': 'notifications',
    'Notification.unreadCount': 'notifications/unread-count',
    'Notification.markRead': 'notifications/:id/read',
    'Notification.markAllRead': 'notifications/read-all',
    'Notification.delete': 'notifications/:id',
  };
}
