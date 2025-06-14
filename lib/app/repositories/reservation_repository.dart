import 'dart:async';

import 'package:room_reservation_mobile_app/app/models/meta_data_response.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';

class ReservationRepository {
  static const int _pageSize = 10;
  final _reservationsController =
      StreamController<
        ({List<Reservation> reservations, MetaDataResponse metadata})
      >.broadcast();

  bool _isLoading = false;
  int _currentPage = 1;
  final _reservations = <Reservation>[];
  MetaDataResponse? _metadata;
  late final ReservationService _service;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  ReservationRepository() {
    _initService();
  }

  Future<void> _initService() async {
    if (_isInitialized) return;
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();
    try {
      _service = await ReservationService.getInstance();
      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    } finally {
      _initCompleter = null;
    }
  }

  Stream<({List<Reservation> reservations, MetaDataResponse metadata})>
  get reservationsStream => _reservationsController.stream;

  MetaDataResponse? get metadata => _metadata;
  bool get hasMoreData => _metadata?.hasNextPage ?? true;
  bool get isLoading => _isLoading;

  Future<void> loadMoreReservations() async {
    // Prevent concurrent loading
    if (_isLoading) return;

    // Stop if we know there's no more data
    if (_metadata != null && !hasMoreData) return;

    _isLoading = true;

    try {
      // Ensure service is initialized
      await _initService();

      // Emit loading state with current data
      if (_reservations.isNotEmpty) {
        _reservationsController.add((
          reservations: List.from(_reservations),
          metadata: _metadata ?? MetaDataResponse(hasNextPage: true),
        ));
      }

      final response = await _service.getAllReservations(
        page: _currentPage,
        limit: _pageSize,
      );

      final newReservations = response.data ?? [];
      _reservations.addAll(newReservations);

      // Update metadata from response
      _metadata = response.metaData;
      _currentPage++;

      // Emit updated list
      _reservationsController.add((
        reservations: List.from(_reservations),
        metadata: _metadata!,
      ));
    } catch (e) {
      // Only emit error if no data yet
      if (_reservations.isEmpty) {
        _reservationsController.addError(e);
      }
    } finally {
      _isLoading = false;
    }
  }

  void refresh() {
    _currentPage = 1;
    _metadata = null;
    _reservations.clear();
    loadMoreReservations();
  }

  void dispose() {
    _reservationsController.close();
  }
}
