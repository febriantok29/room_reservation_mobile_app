import 'package:room_reservation_mobile_app/app/models/meta_data_response.dart';

/// Model untuk response API standar
class ApiResponse<T> {
  final String message;
  final T? data;
  final MetaDataResponse? metaData;

  const ApiResponse({required this.message, this.data, this.metaData});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    T data;

    if (json['data'] == null) {
      data = null as T;
    } else if (fromJsonT != null) {
      data = fromJsonT(json['data']);
    } else {
      data = json['data'] as T;
    }

    return ApiResponse<T>(
      message: json['message'] ?? '',
      data: data,
      metaData: json['metaData'] != null
          ? MetaDataResponse.fromJson(json['metaData'])
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T)? toJsonT) {
    return {
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
      'metaData': metaData,
    };
  }
}
