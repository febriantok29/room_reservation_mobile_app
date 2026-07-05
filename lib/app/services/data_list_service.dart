import 'package:rapa_track_mobile_app/app/models/base_list_model.dart';
import 'package:rapa_track_mobile_app/app/models/pagination.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';

/// Generic service untuk API list calls dengan caching dan pagination support
abstract class DataListService<T> {
  /// Endpoint route key (dari DefaultApiRoutes)
  String get routeKey;

  /// Convert JSON response ke model T
  T fromJson(Map<String, dynamic> json);

  /// Cache settings
  final _cacheExpirationLimit = const Duration(minutes: 5);
  BaseListModel<T>? _cachedData;
  DateTime? _cacheTimestamp;

  void clearCache() {
    _cachedData = null;
    _cacheTimestamp = null;
  }

  bool _isCacheValid() {
    if (_cachedData == null || _cacheTimestamp == null) {
      return false;
    }
    return DateTime.now().difference(_cacheTimestamp!) < _cacheExpirationLimit;
  }

  /// Fetch list dari API dengan pagination
  Future<BaseListModel<T>> getList({
    required int page,
    required int perPage,
    Map<String, dynamic>? filters,
    bool refreshCache = false,
  }) async {
    final isFirstPage = page == 1;

    // Return cache jika valid dan bukan refresh
    if (!refreshCache && isFirstPage && _isCacheValid()) {
      return _cachedData!;
    }

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        ...?filters,
      };

      final response = await RouteBuilder(routeKey, queries: queryParams).get();

      if (response == null || response is! Map<String, dynamic>) {
        return _createEmptyModel();
      }

      final result = _parseResponse(response);

      // Cache hanya jika page pertama
      if (isFirstPage) {
        _cachedData = result;
        _cacheTimestamp = DateTime.now();
      }

      return result;
    } catch (e) {
      // Return cache jika ada error di page pertama
      if (_cachedData != null && isFirstPage) {
        return _cachedData!;
      }
      rethrow;
    }
  }

  BaseListModel<T> _parseResponse(Map<String, dynamic> response) {
    // Check format: { success, data, metadata }
    if (response['success'] != true) {
      return _createEmptyModel();
    }

    final rawData = response['data'];
    final rawMetadata = response['metadata'];

    if (rawData is! List) {
      return _createEmptyModel();
    }

    final data = rawData
        .whereType<Map<String, dynamic>>()
        .map((item) => fromJson(item))
        .toList();

    final pagination = Pagination.fromJson(rawMetadata);

    return BaseListModel(data: data, pagination: pagination);
  }

  BaseListModel<T> _createEmptyModel() => const BaseListModel.empty();
}
