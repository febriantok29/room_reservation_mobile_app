import 'dart:io';

import 'package:rapa_track_mobile_app/app/models/requests/room_request.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';
import 'package:rapa_track_mobile_app/app/services/data_list_service.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';

class RoomService extends DataListService<Room> {
  @override
  String get routeKey => 'Room.list';

  @override
  Room fromJson(Map<String, dynamic> json) => Room.fromJson(json);

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
      if (startTime != null) 'start_time': DateFormatter.toIsoOrNull(startTime),
      if (endTime != null) 'end_time': DateFormatter.toIsoOrNull(endTime),
      if (facilityIds != null && facilityIds.isNotEmpty)
        'facility_ids': facilityIds,
      if (perPage != null) 'per_page': perPage,
      if (page != null) 'page': page,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final response = await RouteBuilder(
      'Room.list',
      queries: query.isNotEmpty ? query : null,
    ).get();

    final data = _readSuccessPayload(response);

    if (data is! List) {
      return <Room>[];
    }

    return data.map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Room> getRoomDetail(String roomId) async {
    final response = await RouteBuilder(
      'Room.detail',
      params: {'id': roomId},
    ).get();

    final data = _readSuccessPayload(response);
    return Room.fromJson(data);
  }

  Future<RoomAvailabilityResult> getRoomAvailability({
    required String roomId,
    required String date,
    int? intervalMinutes,
  }) async {
    final response = await RouteBuilder(
      'Room.availability',
      params: {'id': roomId},
      queries: {
        'date': date,
        if (intervalMinutes != null) 'interval_minutes': intervalMinutes,
      },
    ).get();

    final data = _readSuccessPayload(response);

    final slots =
        (data['available_slots'] as List?)?.whereType<String>().toList() ?? [];

    return RoomAvailabilityResult(
      roomId: data['room_id']?.toString() ?? roomId,
      date: data['date']?.toString() ?? date,
      intervalMinutes: int.tryParse('${data['interval_minutes'] ?? ''}'),
      availableSlots: slots,
    );
  }

  Future<Room> createRoom({required RoomRequest request}) async {
    request.validate();

    final response = await RouteBuilder(
      'Room.create',
    ).post(body: request.toMap());

    final data = _readSuccessPayload(response);
    return Room.fromJson(data);
  }

  Future<Room> updateRoom({
    required String roomId,
    required RoomRequest request,
  }) async {
    request.validate();

    final response = await RouteBuilder(
      'Room.update',
      params: {'id': roomId},
    ).put(body: request.toMap());

    final data = _readSuccessPayload(response);

    return Room.fromJson(data);
  }

  Future<void> deleteRoom(String roomId) =>
      RouteBuilder('Room.delete', params: {'id': roomId}).delete();

  Future<RoomImageResult> uploadImage({
    required String roomId,
    required File image,
  }) async {
    final response = await RouteBuilder(
      'Room.image',
      params: {'id': roomId},
    ).uploadSingleFile(
      fileFieldName: 'image',
      file: image,
    );

    final data = _readSuccessPayload(response);

    if (data is! Map<String, dynamic>) {
      throw 'Format respons upload gambar tidak valid';
    }

    return RoomImageResult(
      imageUrl: data['image_url']?.toString(),
      sizeBytes: int.tryParse('${data['size_bytes'] ?? ''}'),
      wasCompressed: data['was_compressed'] == true,
    );
  }

  Future<void> deleteImage(String roomId) =>
      RouteBuilder('Room.deleteImage', params: {'id': roomId}).delete();

  dynamic _readSuccessPayload(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw 'Format respons room API tidak valid';
    }

    final isSuccess = response['success'];

    if (isSuccess is! bool || isSuccess != true) {
      final errorMessage =
          response['message'] ?? 'Gagal melakukan fetch data ruangan';
      throw errorMessage;
    }

    final data = response['data'];
    return data;
  }
}

class RoomImageResult {
  final String? imageUrl;
  final int? sizeBytes;
  final bool wasCompressed;

  const RoomImageResult({
    this.imageUrl,
    this.sizeBytes,
    this.wasCompressed = false,
  });
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
