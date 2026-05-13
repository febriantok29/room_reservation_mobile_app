import 'package:room_reservation_mobile_app/app/models/meta_data_response.dart';

/// Model untuk response API standar
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final MetaDataResponse? metadata;

  const ApiResponse({
    this.success = false,
    required this.message,
    this.data,
    this.metadata,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    T? data;

    if (json['data'] != null && fromJsonT != null) {
      data = fromJsonT(json['data']);
    } else {
      data = json['data'] as T?;
    }

    return ApiResponse<T>(
      success: json['success'] == true,
      message: '${json['message'] ?? ''}',
      data: data,
      metadata: json['metadata'] != null
          ? MetaDataResponse.fromJson(json['metadata'])
          : null,
    );
  }
}
