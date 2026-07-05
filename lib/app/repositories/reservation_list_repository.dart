import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/repositories/data_list_repository.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';

class ReservationListRepository extends DataListRepository<Reservation> {
  ReservationListRepository() : super(ReservationService(), perPage: 20);
}
