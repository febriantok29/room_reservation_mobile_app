import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/core/config/app_feature_flags.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/room_api_service.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

class RoomListQuery {
  final bool showDeleted;
  final bool showMaintenance;
  final String? searchKeyword;
  final bool forceRefresh;

  const RoomListQuery({
    this.showDeleted = false,
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
        other.showDeleted == showDeleted &&
        other.showMaintenance == showMaintenance &&
        other.searchKeyword == searchKeyword &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode {
    return Object.hash(
      showDeleted,
      showMaintenance,
      searchKeyword,
      forceRefresh,
    );
  }
}

final roomApiServiceProvider = Provider<RoomApiService>((ref) {
  return RoomApiService();
});

final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService.getInstance();
});

final roomListByQueryProvider = FutureProvider.autoDispose
    .family<List<Room>, RoomListQuery>((ref, query) async {
      if (AppFeatureFlags.useApi) {
        return ref
            .read(roomApiServiceProvider)
            .getRoomList(
              availableOnly: query.showMaintenance ? null : true,
              search: query.searchKeyword,
              perPage: 100,
            );
      }

      return ref
          .read(roomServiceProvider)
          .getRoomList(
            showDeleted: query.showDeleted,
            showMaintenance: query.showMaintenance,
            searchKeyword: query.searchKeyword,
            forceRefresh: query.forceRefresh,
          );
    });

@Deprecated(
  'Gunakan roomListByQueryProvider(RoomListQuery) agar filter/read lebih eksplisit dan reusable.',
)
final roomListProvider = FutureProvider.autoDispose<List<Room>>((ref) async {
  return ref.read(roomListByQueryProvider(const RoomListQuery()).future);
});
