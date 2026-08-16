import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/services/room_service.dart';
import 'package:rapa_track_mobile_app/app/services/user_service.dart';

/// Cache opsi filter Ruangan & Karyawan, hidup selama halaman yang
/// membuatnya (mis. ReportListPage) masih ada di navigation stack.
class ReportFilterOptionsCache {
  final _roomService = RoomService();
  final _userService = UserService();

  List<Room>? _rooms;
  List<Profile>? _users;

  Future<List<Room>> rooms() async {
    return _rooms ??= await _roomService.getRoomList(perPage: 100);
  }

  Future<List<Profile>> users() async {
    return _users ??= await _userService.getUsers(perPage: 100);
  }
}
