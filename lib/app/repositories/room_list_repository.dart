import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/repositories/data_list_repository.dart';
import 'package:rapa_track_mobile_app/app/services/room_list_service.dart';

/// Repository untuk Room list dengan pagination
class RoomListRepository extends DataListRepository<Room> {
  RoomListRepository() : super(RoomListService(), perPage: 20);
}
