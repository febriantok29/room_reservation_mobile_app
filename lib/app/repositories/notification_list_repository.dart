import 'package:rapa_track_mobile_app/app/models/notification_model.dart';
import 'package:rapa_track_mobile_app/app/repositories/data_list_repository.dart';
import 'package:rapa_track_mobile_app/app/services/notification_service.dart';

class NotificationListRepository extends DataListRepository<NotificationModel> {
  NotificationListRepository() : super(NotificationService(), perPage: 20);
}
