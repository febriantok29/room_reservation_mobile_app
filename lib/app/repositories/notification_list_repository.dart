import 'package:rapa_track_mobile_app/app/models/notification_model.dart';
import 'package:rapa_track_mobile_app/app/repositories/data_list_repository.dart';
import 'package:rapa_track_mobile_app/app/services/notification_list_service.dart';

/// Repository untuk Notification list dengan pagination
class NotificationListRepository extends DataListRepository<NotificationModel> {
  NotificationListRepository() : super(NotificationListService(), perPage: 20);
}
