import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

class RoomListQuery {
  final bool showMaintenance;
  final String? searchKeyword;
  final bool forceRefresh;

  const RoomListQuery({
    this.showMaintenance = true,
    this.searchKeyword,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RoomListQuery &&
        other.showMaintenance == showMaintenance &&
        other.searchKeyword == searchKeyword &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode {
    return Object.hash(showMaintenance, searchKeyword, forceRefresh);
  }
}

final roomApiServiceProvider = Provider<RoomService>((ref) {
  return RoomService();
});

final roomListByQueryProvider = FutureProvider.autoDispose
    .family<List<Room>, RoomListQuery>((ref, query) async {
      return ref
          .read(roomApiServiceProvider)
          .getRoomList(
            availableOnly: query.showMaintenance ? null : true,
            search: query.searchKeyword,
            perPage: 100,
          );
    });
