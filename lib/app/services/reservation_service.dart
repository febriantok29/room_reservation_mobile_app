import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/meta_data_response.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/network/api_config/default_api.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class ReservationService {
  ReservationService({DefaultApi? api}) : _api = api ?? DefaultApi();

  final DefaultApi _api;

  Future<ReservationListResult> getReservationList({
    String? status,
    String? dateFrom,
    String? dateTo,
    String? roomId,
    int? perPage,
    int? page,
  }) async {
    final response = await RouteBuilder(
      'Reservation.list',
      api: _api,
      queries: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
        if (perPage != null) 'per_page': perPage,
        if (page != null) 'page': page,
      },
    ).get();

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! List) {
      return const ReservationListResult(reservations: [], metadata: null);
    }

    final reservations = rawData
        .whereType<Map<String, dynamic>>()
        .map(_toReservation)
        .toList();

    final metadata = payload['metadata'] != null
        ? MetaDataResponse.fromJson(payload['metadata'])
        : null;

    return ReservationListResult(
      reservations: reservations,
      metadata: metadata,
    );
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

  Future<Reservation> createReservation({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
    required int visitorCount,
    String? userId,
  }) async {
    final body = <String, dynamic>{
      'room_id': roomId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'purpose': purpose,
      'visitor_count': visitorCount,
      if (userId != null) 'user_id': userId,
    };

    final response = await RouteBuilder(
      'Reservation.create',
      api: _api,
    ).post(body: body);

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const ReservationApiException('Format data reservasi tidak valid');
    }

    return _toReservation(rawData);
  }

  Future<Reservation> updateReservation({
    required String reservationId,
    String? roomId,
    DateTime? startTime,
    DateTime? endTime,
    String? purpose,
    int? visitorCount,
  }) async {
    final body = <String, dynamic>{
      if (roomId != null) 'room_id': roomId,
      if (startTime != null) 'start_time': startTime.toUtc().toIso8601String(),
      if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
      if (purpose != null) 'purpose': purpose,
      if (visitorCount != null) 'visitor_count': visitorCount,
    };

    final response = await RouteBuilder(
      'Reservation.update',
      api: _api,
      params: {'id': reservationId},
    ).put(body: body);

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const ReservationApiException('Format data reservasi tidak valid');
    }

    return _toReservation(rawData);
  }

  Future<Reservation> cancelReservation(String reservationId) async {
    final response = await RouteBuilder(
      'Reservation.cancel',
      api: _api,
      params: {'id': reservationId},
    ).post(body: <String, dynamic>{});

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const ReservationApiException('Format data reservasi tidak valid');
    }

    return _toReservation(rawData);
  }

  Future<Reservation> approveReservation(String reservationId) async {
    final response = await RouteBuilder(
      'Reservation.approve',
      api: _api,
      params: {'id': reservationId},
    ).post(body: <String, dynamic>{});

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const ReservationApiException('Format data reservasi tidak valid');
    }

    return _toReservation(rawData);
  }

  Future<Reservation> rejectReservation(String reservationId) async {
    final response = await RouteBuilder(
      'Reservation.reject',
      api: _api,
      params: {'id': reservationId},
    ).post(body: <String, dynamic>{});

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const ReservationApiException('Format data reservasi tidak valid');
    }

    return _toReservation(rawData);
  }

  Future<Reservation> completeReservation(String reservationId) async {
    final response = await RouteBuilder(
      'Reservation.complete',
      api: _api,
      params: {'id': reservationId},
    ).post(body: <String, dynamic>{});

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw const ReservationApiException('Format data reservasi tidak valid');
    }

    return _toReservation(rawData);
  }

  Future<CalendarResult> getCalendar({
    required int year,
    required int month,
  }) async {
    final response = await RouteBuilder(
      'Reservation.calendar',
      api: _api,
      queries: {'year': year, 'month': month},
    ).get();

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    final rawReservations = data is Map<String, dynamic>
        ? data['reservations']
        : payload['reservations'];

    final reservations = (rawReservations is List)
        ? rawReservations
              .whereType<Map<String, dynamic>>()
              .map(_toReservation)
              .toList()
        : <Reservation>[];

    final rawSummary = data is Map<String, dynamic>
        ? data['summary']
        : payload['summary'];

    return CalendarResult(
      year: year,
      month: month,
      reservations: reservations,
      summary: rawSummary is Map<String, dynamic> ? rawSummary : {},
    );
  }

  Reservation _toReservation(Map<String, dynamic> json) {
    final rawStatus = '${json['status'] ?? ''}'.toLowerCase();

    return Reservation(
      id: '${json['id'] ?? ''}',
      userId: json['user_id']?.toString(),
      roomId: json['room_id']?.toString(),
      startTime: DateTime.tryParse('${json['start_time'] ?? ''}')?.toLocal(),
      endTime: DateTime.tryParse('${json['end_time'] ?? ''}')?.toLocal(),
      visitorCount: int.tryParse('${json['visitor_count'] ?? 0}') ?? 0,
      purpose: json['purpose']?.toString(),
      status: ReservationStatusExtension.fromString(rawStatus),
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

    return Profile(
      id: userPayload['id']?.toString(),
      email: userPayload['email']?.toString(),
      employeeId: userPayload['employee_id']?.toString(),
      firstName: userPayload['first_name']?.toString(),
      lastName: userPayload['last_name']?.toString(),
    );
  }

  Map<String, dynamic> _readSuccessPayload(dynamic response) {
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

class ReservationListResult {
  final List<Reservation> reservations;
  final MetaDataResponse? metadata;

  const ReservationListResult({required this.reservations, this.metadata});
}

class CalendarResult {
  final int year;
  final int month;
  final List<Reservation> reservations;
  final Map<String, dynamic> summary;

  const CalendarResult({
    required this.year,
    required this.month,
    required this.reservations,
    this.summary = const {},
  });
}

class ReservationApiException implements Exception {
  final String message;

  const ReservationApiException(this.message);

  @override
  String toString() => message;
}
