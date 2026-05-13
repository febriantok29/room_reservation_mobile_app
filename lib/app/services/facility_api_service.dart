import 'package:room_reservation_mobile_app/app/models/room_facility.dart';
import 'package:room_reservation_mobile_app/app/network/api_config/default_api.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class FacilityApiService {
  FacilityApiService({DefaultApi? api}) : _api = api ?? DefaultApi();

  final DefaultApi _api;

  /// Mengambil daftar fasilitas dengan filter opsional
  Future<List<RoomFacility>> getFacilityList({
    String? search,
    int? perPage,
  }) async {
    final response = await RouteBuilder(
      'Facility.list',
      api: _api,
      queries: {
        if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
        if (perPage != null) 'per_page': perPage,
      },
    ).get();

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    if (data is! List) {
      return <RoomFacility>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((f) => RoomFacility.fromJson(f))
        .toList();
  }

  /// Mengambil detail fasilitas berdasarkan ID
  Future<RoomFacility> getFacilityDetail(String facilityId) async {
    final response = await RouteBuilder(
      'Facility.detail',
      api: _api,
      params: {'id': facilityId},
    ).get();

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    if (data is! Map<String, dynamic>) {
      throw const FacilityApiException('Format detail fasilitas tidak valid');
    }

    return RoomFacility.fromJson(data);
  }

  /// Membuat fasilitas baru (admin)
  Future<RoomFacility> createFacility({required String name}) async {
    final response = await RouteBuilder(
      'Facility.create',
      api: _api,
    ).post({'name': name});

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    if (data is! Map<String, dynamic>) {
      throw const FacilityApiException('Format data fasilitas tidak valid');
    }

    return RoomFacility.fromJson(data);
  }

  /// Memperbarui fasilitas (admin)
  Future<RoomFacility> updateFacility({
    required String facilityId,
    required String name,
  }) async {
    final response = await RouteBuilder(
      'Facility.update',
      api: _api,
      params: {'id': facilityId},
    ).put({'name': name});

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    if (data is! Map<String, dynamic>) {
      throw const FacilityApiException('Format data fasilitas tidak valid');
    }

    return RoomFacility.fromJson(data);
  }

  /// Menghapus fasilitas (admin)
  Future<void> deleteFacility(String facilityId) async {
    final response = await RouteBuilder(
      'Facility.delete',
      api: _api,
      params: {'id': facilityId},
    ).delete();

    _readSuccessPayload(response);
  }

  Map<String, dynamic> _readSuccessPayload(RouteResponse response) {
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw const FacilityApiException(
        'Format respons fasilitas API tidak valid',
      );
    }

    if (!response.isSuccess || data['success'] != true) {
      throw FacilityApiException(
        '${data['message'] ?? 'Permintaan fasilitas API gagal'}',
      );
    }

    return data;
  }
}

class FacilityApiException implements Exception {
  final String message;

  const FacilityApiException(this.message);

  @override
  String toString() => message;
}
