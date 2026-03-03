import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/network/api_config/default_api.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class ReservationApiService {
  ReservationApiService({DefaultApi? api}) : _api = api ?? DefaultApi();

  final DefaultApi _api;

  Future<List<Reservation>> getReservationList({
    String? status,
    String? startDate,
    String? endDate,
    int? perPage,
  }) async {
    final response = await RouteBuilder(
      'Reservation.list',
      api: _api,
      queries: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
        if (perPage != null) 'per_page': perPage,
      },
    ).get();

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! List) {
      return [];
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(_toReservation)
        .toList();
  }

  Future<Reservation> getReservationDetail(String reservationId) async {
    final response = await RouteBuilder(
      'Reservation.detail',
      api: _api,
      params: {'id': reservationId},
    ).get();

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const ReservationApiException(
        'Format detail reservasi tidak valid',
      );
    }

    return _toReservation(rawData);
  }

  Reservation _toReservation(Map<String, dynamic> json) {
    final rawStatus = '${json['status'] ?? ''}'.toLowerCase();

    return Reservation(
      id: '${json['id'] ?? ''}',
      startTime: DateTime.tryParse('${json['start_time'] ?? ''}')?.toLocal(),
      endTime: DateTime.tryParse('${json['end_time'] ?? ''}')?.toLocal(),
      visitorCount: int.tryParse('${json['visitor_count'] ?? 0}') ?? 0,
      purpose: json['purpose']?.toString(),
      status: _mapStatus(rawStatus),
      room: _toRoom(json),
      user: _toProfile(json),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}')?.toLocal(),
    );
  }

  Room? _toRoom(Map<String, dynamic> json) {
    final roomPayload = json['room'];

    if (roomPayload is Map<String, dynamic>) {
      return Room.fromJson(roomPayload);
    }

    final roomId = json['room_id']?.toString();

    if (roomId == null || roomId.isEmpty) {
      return null;
    }

    return Room(id: roomId);
  }

  Profile? _toProfile(Map<String, dynamic> json) {
    final userPayload = json['user'];

    if (userPayload is! Map<String, dynamic>) {
      return null;
    }

    final fullName = '${userPayload['name'] ?? ''}'.trim();
    final chunks = fullName
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    return Profile(
      id: userPayload['id']?.toString(),
      email: userPayload['email']?.toString(),
      employeeId: userPayload['employee_id']?.toString(),
      firstName: chunks.isNotEmpty ? chunks.first : null,
      lastName: chunks.length > 1 ? chunks.sublist(1).join(' ') : null,
    );
  }

  ReservationStatus _mapStatus(String status) {
    switch (status) {
      case 'pending':
      case 'approved':
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'upcoming':
        return ReservationStatus.upcoming;
      case 'ongoing':
        return ReservationStatus.ongoing;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
      case 'rejected':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.confirmed;
    }
  }

  Map<String, dynamic> _readSuccessPayload(RouteResponse response) {
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw const ReservationApiException(
        'Format respons reservasi API tidak valid',
      );
    }

    if (!response.isSuccess || data['success'] != true) {
      throw ReservationApiException(
        '${data['message'] ?? 'Permintaan reservasi API gagal'}',
      );
    }

    return data;
  }
}

class ReservationApiException implements Exception {
  final String message;

  const ReservationApiException(this.message);

  @override
  String toString() => message;
}
