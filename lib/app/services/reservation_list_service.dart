import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/services/data_list_service.dart';

/// Concrete implementation untuk Reservation list dengan pagination
class ReservationListService extends DataListService<Reservation> {
  @override
  String get routeKey => 'Reservation.list';

  @override
  Reservation fromJson(Map<String, dynamic> json) => Reservation.fromJson(json);
}
