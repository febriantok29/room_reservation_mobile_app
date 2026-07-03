import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/repositories/data_list_repository.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_list_service.dart';

/// Repository untuk Reservation list dengan pagination
class ReservationListRepository extends DataListRepository<Reservation> {
  ReservationListRepository() : super(ReservationListService(), perPage: 20);
}
