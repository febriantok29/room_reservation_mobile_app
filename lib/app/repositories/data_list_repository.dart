import 'package:rapa_track_mobile_app/app/services/data_list_service.dart';

/// Generic repository untuk handle pagination logic dengan list data
class DataListRepository<T> {
  final DataListService<T> _service;

  List<T> data = [];

  int _currentPage = 1;
  final int _perPage;

  bool isFetching = false;
  bool hasMoreData = true;

  DataListRepository(this._service, {int perPage = 25}) : _perPage = perPage;

  /// Fetch list data dari service dengan pagination support
  Future<void> fetchList({
    Map<String, dynamic>? filters,
    bool isRefresh = false,
  }) async {
    // Reset jika refresh
    if (isRefresh) {
      _currentPage = 1;
      hasMoreData = true;
      data.clear();
    }

    // Guard: jangan fetch jika sudah fetching atau tidak ada data lagi
    if (isFetching || !hasMoreData) {
      return;
    }

    isFetching = true;

    try {
      final response = await _service.getList(
        page: _currentPage,
        perPage: _perPage,
        filters: filters,
        refreshCache: isRefresh,
      );

      if (isRefresh) {
        data = response.data;
      } else {
        data.addAll(response.data);
      }

      // Update pagination state
      if (response.pagination.currentPage >= response.pagination.lastPage) {
        hasMoreData = false;
      } else {
        hasMoreData = true;
        _currentPage++;
      }
    } catch (error) {
      rethrow;
    } finally {
      isFetching = false;
    }
  }

  /// Reset repository ke state awal
  void reset() {
    data.clear();
    _currentPage = 1;
    hasMoreData = true;
    isFetching = false;
    _service.clearCache();
  }

  /// Dispose resources
  void dispose() {
    reset();
  }
}
