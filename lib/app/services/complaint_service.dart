import 'package:rapa_track_mobile_app/app/models/complaint.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';

class ComplaintService {
  /// Get list of complaints
  Future<List<Complaint>> getComplaintList({
    String? status,
    String? roomId,
    int? perPage,
    int? page,
  }) async {
    final queries = <String, dynamic>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
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

  /// Get complaint detail
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

  /// Create new complaint
  Future<Complaint> createComplaint({
    required String roomId,
    required String message,
  }) async {
    final body = <String, dynamic>{'room_id': roomId, 'message': message};

    final response = await RouteBuilder('Complaint.create').post(body: body);

    final payload = _readSuccessPayload(response);
    final rawData = payload['data'];

    if (rawData is! Map<String, dynamic>) {
      throw 'Format data keluhan tidak valid';
    }

    return Complaint.fromJson(rawData);
  }

  /// Update complaint status (Admin only)
  Future<Complaint> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminResponse,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      if (adminResponse != null && adminResponse.isNotEmpty)
        'admin_response': adminResponse,
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
