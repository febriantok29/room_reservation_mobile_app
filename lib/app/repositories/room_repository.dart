import 'dart:async';

import 'package:room_reservation_mobile_app/app/models/api_response.dart';
import 'package:room_reservation_mobile_app/app/models/meta_data_response.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

class RoomRepository {
  static final RoomRepository _instance = RoomRepository._internal();

  factory RoomRepository() => _instance;

  RoomRepository._internal() {
    _initService();
  }

  static RoomRepository getInstance() => _instance;

  static const int _pageSize = 10;

  final _roomsController =
      StreamController<
        ({List<Room> rooms, MetaDataResponse metadata})
      >.broadcast();

  bool _isLoading = false;
  int _currentPage = 1;
  final _rooms = <Room>[];
  MetaDataResponse? _metadata;
  late final RoomService _service;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  // Cache params for reload/refresh
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;

  Future<void> _initService() async {
    if (_isInitialized) return;
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();
    try {
      _service = RoomService.getInstance();
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    } finally {
      _initCompleter = null;
    }
  }

  Stream<({List<Room> rooms, MetaDataResponse metadata})> get roomsStream =>
      _roomsController.stream;

  MetaDataResponse? get metadata => _metadata;
  bool get hasMoreData => _metadata?.hasNextPage ?? true;
  bool get isLoading => _isLoading;

  Future<void> loadMoreRooms({DateTime? start, DateTime? end}) async {
    // Use last params if not provided
    start = start ?? _lastStartDate;
    end = end ?? _lastEndDate;

    // Save params for future use
    if (start != null) _lastStartDate = start;
    if (end != null) _lastEndDate = end;

    // Validate required params
    if (start == null || end == null) {
      _roomsController.addError(Exception('Start and end dates are required'));
      return;
    }

    // Prevent concurrent loading
    if (_isLoading) return;

    // Stop if we know there's no more data
    if (_metadata != null && !hasMoreData) return;

    _isLoading = true;

    try {
      // Ensure service is initialized
      await _initService();

      // Emit loading state with current data
      if (_rooms.isNotEmpty) {
        _roomsController.add((
          rooms: List.from(_rooms),
          metadata: _metadata ?? MetaDataResponse(hasNextPage: true),
        ));
      }

      final response = await _service.getRawAvailableRoom(
        start: start,
        end: end,
        page: _currentPage,
        limit: _pageSize,
      );

      final newRooms = response.data ?? [];
      _rooms.addAll(newRooms);

      // Update metadata from response or create a new one
      _metadata =
          response.metaData ??
          MetaDataResponse(
            hasNextPage: newRooms.length == _pageSize,
            currentPage: _currentPage,
            itemsPerPage: _pageSize,
          );

      _currentPage++;

      // Emit updated list
      _roomsController.add((rooms: List.from(_rooms), metadata: _metadata!));
    } catch (e) {
      // Only emit error if no data yet
      if (_rooms.isEmpty) {
        _roomsController.addError(e);
      }
    } finally {
      _isLoading = false;
    }
  }

  void refresh() {
    _currentPage = 1;
    _metadata = null;
    _rooms.clear();
    loadMoreRooms();
  }

  void dispose() {
    _roomsController.close();
  }

  // Legacy method - maintained for compatibility
  Stream<ApiResponse<List<Room>>> getAvailableRoomsStream({
    required DateTime start,
    required DateTime end,
  }) {
    refresh();
    loadMoreRooms(start: start, end: end);

    return _roomsController.stream.map(
      (data) => ApiResponse<List<Room>>(
        message: 'Rooms fetched',
        data: data.rooms,
        metaData: data.metadata,
      ),
    );
  }

  // Method to get a single page of rooms
  Future<ApiResponse<List<Room>>> getAvailableRoomsPage({
    required DateTime start,
    required DateTime end,
    required int page,
    int limit = _pageSize,
  }) async {
    try {
      return await _service.getRawAvailableRoom(
        start: start,
        end: end,
        page: page,
        limit: limit,
      );
    } catch (e) {
      return ApiResponse<List<Room>>(
        message: 'Error fetching rooms: $e',
        data: [],
      );
    }
  }
}
