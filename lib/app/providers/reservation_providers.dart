import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_api_service.dart';

class ReservationListQuery {
  final Profile user;
  final ReservationStatus? status;

  const ReservationListQuery({required this.user, this.status});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ReservationListQuery &&
        other.user.id == user.id &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(user.id, status);
}

final reservationApiServiceProvider = Provider<ReservationApiService>((ref) {
  return ReservationApiService();
});

final reservationListByQueryProvider = FutureProvider.autoDispose
    .family<List<Reservation>, ReservationListQuery>((ref, query) async {
      final result = await ref
          .read(reservationApiServiceProvider)
          .getReservationList(
            status: query.status?.toApiString(),
            perPage: 100,
          );
      return result.reservations;
    });

/// Query untuk kalender reservasi bulanan
class CalendarQuery {
  final int year;
  final int month;

  const CalendarQuery({required this.year, required this.month});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarQuery && other.year == year && other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}

final calendarReservationProvider = FutureProvider.autoDispose
    .family<CalendarResult, CalendarQuery>((ref, query) async {
      return ref
          .read(reservationApiServiceProvider)
          .getCalendar(year: query.year, month: query.month);
    });
