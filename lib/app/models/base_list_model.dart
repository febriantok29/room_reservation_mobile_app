import 'package:rapa_track_mobile_app/app/models/pagination.dart';

/// Generic response model untuk list data dari API
class BaseListModel<T> {
  final List<T> data;
  final Pagination pagination;

  const BaseListModel({required this.data, required this.pagination});

  /// Empty list model
  const BaseListModel.empty()
    : data = const [],
      pagination = const Pagination.empty();

  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;
  int get length => data.length;

  factory BaseListModel.fromJson({
    required dynamic json,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    if (json is! Map<String, dynamic>) {
      return const BaseListModel.empty();
    }

    final rawData = json['data'];
    final rawPagination = json['metadata'] ?? json['pagination'];

    List<T> data = [];
    if (rawData is List) {
      data = rawData
          .whereType<Map<String, dynamic>>()
          .map((item) => fromJson(item))
          .toList();
    }

    final pagination = Pagination.fromJson(rawPagination);

    return BaseListModel(data: data, pagination: pagination);
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) => {
    'data': data.map((item) => toJson(item)).toList(),
    'metadata': pagination.toJson(),
  };
}
