import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/network/api_config/default_api.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class RoomService {
  RoomService({DefaultApi? api}) : _api = api ?? DefaultApi();

  final DefaultApi _api;

  Future<List<Room>> getRoomList({
    int? floor,
    int? minCapacity,
    bool? availableOnly,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? facilityIds,
    int? perPage,
    int? page,
    String? search,
  }) async {
    final query = <String, dynamic>{
      if (floor != null) 'floor': floor,
      if (minCapacity != null) 'min_capacity': minCapacity,
      if (availableOnly != null) 'available_only': availableOnly,
      if (startTime != null) 'start_time': startTime.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
      if (facilityIds != null && facilityIds.isNotEmpty)
        'facility_ids': facilityIds,
      if (perPage != null) 'per_page': perPage,
      if (page != null) 'page': page,
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

  Future<RoomAvailabilityResult> getRoomAvailability({
    required String roomId,
    required String date,
    int? intervalMinutes,
  }) async {
    final response = await RouteBuilder(
      'Room.availability',
      api: _api,
      params: {'id': roomId},
      queries: {
        'date': date,
        if (intervalMinutes != null) 'interval_minutes': intervalMinutes,
      },
    ).get();

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    if (data is! Map<String, dynamic>) {
      return RoomAvailabilityResult(
        roomId: roomId,
        date: date,
        availableSlots: [],
      );
    }

    final slots =
        (data['available_slots'] as List?)?.whereType<String>().toList() ?? [];

    return RoomAvailabilityResult(
      roomId: data['room_id']?.toString() ?? roomId,
      date: data['date']?.toString() ?? date,
      intervalMinutes: int.tryParse('${data['interval_minutes'] ?? ''}'),
      availableSlots: slots,
    );
  }

  Future<Room> createRoom({
    required String name,
    required int floor,
    required int capacity,
    String? description,
    bool? isMaintenance,
    List<String>? facilityIds,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'floor': floor,
      'capacity': capacity,
      if (description != null) 'description': description,
      if (isMaintenance != null) 'is_maintenance': isMaintenance,
      if (facilityIds != null) 'facility_ids': facilityIds,
    };

    final response = await RouteBuilder(
      'Room.create',
      api: _api,
    ).post(body: body);

    final payload = _readSuccessPayload(response);
    return Room.fromJson(payload['data']);
  }

  Future<Room> updateRoom({
    required String roomId,
    String? name,
    int? floor,
    int? capacity,
    String? description,
    bool? isMaintenance,
    List<String>? facilityIds,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (floor != null) 'floor': floor,
      if (capacity != null) 'capacity': capacity,
      if (description != null) 'description': description,
      if (isMaintenance != null) 'is_maintenance': isMaintenance,
      if (facilityIds != null) 'facility_ids': facilityIds,
    };

    final response = await RouteBuilder(
      'Room.update',
      api: _api,
      params: {'id': roomId},
    ).put(body: body);

    final payload = _readSuccessPayload(response);
    return Room.fromJson(payload['data']);
  }

  Future<void> deleteRoom(String roomId) async {
    final response = await RouteBuilder(
      'Room.delete',
      api: _api,
      params: {'id': roomId},
    ).delete();

    _readSuccessPayload(response);
  }

  Map<String, dynamic> _readSuccessPayload(dynamic response) {
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

class RoomAvailabilityResult {
  final String roomId;
  final String date;
  final int? intervalMinutes;
  final List<String> availableSlots;

  const RoomAvailabilityResult({
    required this.roomId,
    required this.date,
    this.intervalMinutes,
    required this.availableSlots,
  });
}

class RoomApiException implements Exception {
  final String message;

  const RoomApiException(this.message);

  @override
  String toString() => message;
}
