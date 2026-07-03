import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/services/data_list_service.dart';

/// Concrete implementation untuk Room list dengan pagination
class RoomListService extends DataListService<Room> {
  @override
  String get routeKey => 'Room.list';

  @override
  Room fromJson(Map<String, dynamic> json) => Room.fromJson(json);
}
