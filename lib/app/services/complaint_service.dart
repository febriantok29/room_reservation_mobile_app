import 'dart:io';

import 'package:rapa_track_mobile_app/app/models/complaint.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';
import 'package:rapa_track_mobile_app/app/services/data_list_service.dart';

class ComplaintService extends DataListService<Complaint> {
  @override
  String get routeKey => 'Complaint.list';

  @override
  Complaint fromJson(Map<String, dynamic> json) => Complaint.fromJson(json);

  Future<List<Complaint>> getComplaintList({
    String? status,
    String? roomId,
    String? reservationId,
    int? perPage,
    int? page,
  }) async {
    final queries = <String, dynamic>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      if (reservationId != null && reservationId.isNotEmpty)
        'reservation_id': reservationId,
      if (perPage != null) 'per_page': perPage,
      if (page != null) 'page': page,
    };

    final response = await RouteBuilder(
      'Complaint.list',
      queries: queries.isNotEmpty ? queries : null,
    ).get();

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! List) {
      return [];
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map((json) => Complaint.fromJson(json))
        .toList();
  }

  Future<Complaint> getComplaintDetail(String complaintId) async {
    final response = await RouteBuilder(
      'Complaint.detail',
      params: {'id': complaintId},
    ).get();

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw 'Format detail keluhan tidak valid';
    }

    return Complaint.fromJson(rawData);
  }

  Future<Complaint> createComplaint({
    required String reservationId,
    required String title,
    required String description,
    String? facilityId,
    File? photo,
  }) async {
    final body = <String, dynamic>{
      'reservation_id': reservationId,
      'title': title,
      'description': description,
      if (facilityId != null && facilityId.isNotEmpty) 'facility_id': facilityId,
      if (photo != null) 'photo': photo,
    };

    final response = await RouteBuilder('Complaint.create').postFile(body);

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw 'Format data keluhan tidak valid';
    }

    return Complaint.fromJson(rawData);
  }

  Future<Complaint> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? resolutionNotes,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      if (resolutionNotes != null && resolutionNotes.isNotEmpty)
        'resolution_notes': resolutionNotes,
    };

    final response = await RouteBuilder(
      'Complaint.updateStatus',
      params: {'id': complaintId},
    ).patch(body: body);

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw 'Format data keluhan tidak valid';
    }

    return Complaint.fromJson(rawData);
  }

  dynamic _readSuccessPayload(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw 'Format respons complaint API tidak valid';
    }

    final isSuccess = response['success'];

    if (isSuccess is! bool || isSuccess != true) {
      final errorMessage =
          response['message'] ?? 'Gagal melakukan fetch data keluhan';
      throw errorMessage;
    }

    return response;
  }
}
