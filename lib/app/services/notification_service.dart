import 'package:rapa_track_mobile_app/app/models/notification_model.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';
import 'package:rapa_track_mobile_app/app/services/data_list_service.dart';

class NotificationService extends DataListService<NotificationModel> {
  @override
  String get routeKey => 'Notification.list';

  @override
  NotificationModel fromJson(Map<String, dynamic> json) =>
      NotificationModel.fromJson(json);

  /// Get list of notifications
  Future<List<NotificationModel>> getNotificationList({
    bool? isRead,
    int perPage = 50,
    int? page,
  }) async {
    final queries = <String, dynamic>{
      if (isRead != null) 'is_read': isRead,
      'per_page': perPage,
      if (page != null) 'page': page,
    };

    final response = await RouteBuilder(
      'Notification.list',
      queries: queries.isNotEmpty ? queries : null,
    ).get();

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! List) {
      return [];
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final response = await RouteBuilder('Notification.unreadCount').get();

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is Map<String, dynamic>) {
      return int.tryParse('${rawData['unread_count'] ?? 0}') ?? 0;
    }

    return 0;
  }

  /// Mark notification as read
  Future<NotificationModel> markAsRead(String notificationId) async {
    final response = await RouteBuilder(
      'Notification.markRead',
      params: {'id': notificationId},
    ).post(body: <String, dynamic>{});

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw 'Format data notifikasi tidak valid';
    }

    return NotificationModel.fromJson(rawData);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await RouteBuilder(
      'Notification.markAllRead',
    ).post(body: <String, dynamic>{});
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await RouteBuilder(
      'Notification.delete',
      params: {'id': notificationId},
    ).delete();
  }

  dynamic _readSuccessPayload(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw 'Format respons notification API tidak valid';
    }

    final isSuccess = response['success'];

    if (isSuccess is! bool || isSuccess != true) {
      final errorMessage =
          response['message'] ?? 'Gagal melakukan fetch data notifikasi';
      throw errorMessage;
    }

    return response;
  }
}
