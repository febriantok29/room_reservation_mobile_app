import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/network/api_config/default_api.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class RoomApiService {
  RoomApiService({DefaultApi? api}) : _api = api ?? DefaultApi();

  final DefaultApi _api;

  Future<List<Room>> getRoomList({
    int? floor,
    int? minCapacity,
    bool? availableOnly,
    int? perPage,
    String? search,
  }) async {
    final query = <String, dynamic>{
      if (floor != null) 'floor': floor,
      if (minCapacity != null) 'min_capacity': minCapacity,
      if (availableOnly != null) 'available_only': availableOnly,
      if (perPage != null) 'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final response = await RouteBuilder(
      'Room.list',
      api: _api,
      queries: query,
    ).get();

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    if (data is! List) {
      return <Room>[];
    }

    return data.map(Room.fromJson).toList();
  }

  Future<Room> getRoomDetail(String roomId) async {
    final response = await RouteBuilder(
      'Room.detail',
      api: _api,
      params: {'id': roomId},
    ).get();

    final payload = _readSuccessPayload(response);
    return Room.fromJson(payload['data']);
  }

  Map<String, dynamic> _readSuccessPayload(RouteResponse response) {
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw RoomApiException('Format respons room API tidak valid');
    }

    if (!response.isSuccess || data['success'] != true) {
      throw RoomApiException(
        '${data['message'] ?? 'Permintaan room API gagal'}',
      );
    }

    return data;
  }
}

class RoomApiException implements Exception {
  final String message;

  const RoomApiException(this.message);

  @override
  String toString() => message;
}
