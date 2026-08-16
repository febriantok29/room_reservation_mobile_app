import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';

class FacilityCreateResult {
  final int addedCount;
  final List<String> skipped;
  final List<RoomFacility> facilities;

  const FacilityCreateResult({
    required this.addedCount,
    required this.skipped,
    required this.facilities,
  });
}

class FacilityService {
  static List<RoomFacility>? _cache;

  Future<List<RoomFacility>> getFacilityList({
    String? search,
    int? perPage,
    bool forceRefresh = false,
  }) async {
    if (_cache != null && !forceRefresh) {
      if (search == null || search.isEmpty) return _cache!;

      return _cache!
          .where((f) => f.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

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

    final facilities = data
        .whereType<Map<String, dynamic>>()
        .map((f) => RoomFacility.fromJson(f))
        .toList();

    if (search == null || search.isEmpty) {
      _cache = facilities;
    }

    return facilities;
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
    final result = await createFacilities([name]);
    if (result.facilities.isEmpty) {
      throw 'Fasilitas tidak berhasil ditambahkan';
    }
    return result.facilities.first;
  }

  Future<FacilityCreateResult> createFacilities(List<String> names) async {
    final response = await RouteBuilder(
      'Facility.create',
    ).post(body: {'names': names});

    final data = _readSuccessPayload(response);

    _cache = null;

    final facilities = <RoomFacility>[];
    final rawList = data['facilities'];

    if (rawList is List) {
      facilities.addAll(
        rawList
            .whereType<Map<String, dynamic>>()
            .map((f) => RoomFacility.fromJson(f))
            .toList(),
      );
    }

    final skipped = <String>[];
    final rawSkipped = data['skipped'];

    if (rawSkipped is List) {
      skipped.addAll(rawSkipped.whereType<String>());
    }

    return FacilityCreateResult(
      addedCount: data['added_count'] is int ? data['added_count'] as int : facilities.length,
      skipped: skipped,
      facilities: facilities,
    );
  }

  Future<RoomFacility> updateFacility({
    required String facilityId,
    required String name,
  }) async {
    final response = await RouteBuilder(
      'Facility.update',
      params: {'id': facilityId},
    ).put(body: {'name': name});

    _cache = null;

    final data = _readSuccessPayload(response);

    return RoomFacility.fromJson(data);
  }

  Future<void> deleteFacility(String facilityId) async {
    await RouteBuilder('Facility.delete', params: {'id': facilityId}).delete();
    _cache = null;
  }

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
