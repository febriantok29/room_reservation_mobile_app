import 'package:rapa_track_mobile_app/app/models/notification_model.dart';
import 'package:rapa_track_mobile_app/app/services/data_list_service.dart';

/// Concrete implementation untuk Notification list dengan pagination
class NotificationListService extends DataListService<NotificationModel> {
  @override
  String get routeKey => 'Notification.list';

  @override
  NotificationModel fromJson(Map<String, dynamic> json) =>
      NotificationModel.fromJson(json);
}
