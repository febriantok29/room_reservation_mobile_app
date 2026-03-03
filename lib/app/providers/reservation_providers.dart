import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/core/config/app_feature_flags.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_api_service.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';

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

final reservationServiceProvider = Provider<ReservationService>((ref) {
  return ReservationService.getInstance();
});

final reservationListByQueryProvider = FutureProvider.autoDispose
    .family<List<Reservation>, ReservationListQuery>((ref, query) async {
      if (AppFeatureFlags.useApi) {
        return ref
            .read(reservationApiServiceProvider)
            .getReservationList(
              status: query.status?.toFirestoreString(),
              perPage: 100,
            );
      }

      return ref
          .read(reservationServiceProvider)
          .getReservationList(
            userId: query.user.isAdmin ? null : query.user.reference,
          );
    });
