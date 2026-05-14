import 'package:room_reservation_mobile_app/app/models/room_facility.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class FacilityService {
  Future<List<RoomFacility>> getFacilityList({
    String? search,
    int? perPage,
  }) async {
    final queries = <String, String>{};

    if (search != null && search.isNotEmpty) {
      queries['q'] = search.trim();
    }

    if (perPage != null) {
      queries['per_page'] = perPage.toString();
    }

    final router = RouteBuilder(
      'Facility.list',
      queries: queries.isNotEmpty ? queries : null,
    );
    final response = await router.get();

    final result = <RoomFacility>[];

    if (response is! Map<String, dynamic>) {
      return result;
    }

    final data = response['data'];

    if (data is! List) {
      return result;
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((f) => RoomFacility.fromJson(f))
        .toList();
  }

  Future<RoomFacility?> getFacilityDetail(String facilityId) async {
    final router = RouteBuilder('Facility.detail', params: {'id': facilityId});
    final response = await router.get();

    if (response is! Map<String, dynamic>) {
      return null;
    }

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      return null;
    }

    return RoomFacility.fromJson(data);
  }

  Future<RoomFacility> createFacility({required String name}) async {
    final response = await RouteBuilder(
      'Facility.create',
    ).post(body: {'name': name});

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    if (data is! Map<String, dynamic>) {
      throw 'Format data fasilitas tidak valid';
    }

    return RoomFacility.fromJson(data);
  }

  Future<RoomFacility> updateFacility({
    required String facilityId,
    required String name,
  }) async {
    final response = await RouteBuilder(
      'Facility.update',
      params: {'id': facilityId},
    ).put(body: {'name': name});

    final payload = _readSuccessPayload(response);
    final data = payload['data'];

    if (data is! Map<String, dynamic>) {
      throw 'Format data fasilitas tidak valid';
    }

    return RoomFacility.fromJson(data);
  }

  Future<void> deleteFacility(String facilityId) =>
      RouteBuilder('Facility.delete', params: {'id': facilityId}).delete();

  Map<String, dynamic> _readSuccessPayload(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw 'Format respons fasilitas API tidak valid';
    }

    final isSuccess = response['success'];

    if (isSuccess is! bool || isSuccess != true) {
      final errorMessage =
          response['message'] ?? 'Gagal melakukan fetch fasilitas';

      throw errorMessage;
    }

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw 'Format respons fasilitas API tidak valid';
    }

    return data;
  }
}
