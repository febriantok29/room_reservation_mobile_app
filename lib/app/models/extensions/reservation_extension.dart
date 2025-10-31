import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';

extension ReservationX on Reservation {
  /// Format reservation date time menjadi string yang readable
  String get formattedStartTime =>
      startTime != null ? DateFormatter.fullDateTime(startTime!) : '';

  String get formattedEndTime =>
      endTime != null ? DateFormatter.fullDateTime(endTime!) : '';

  String get formattedRange {
    final startDate = startTime;
    final endDate = endTime;

    if (startDate == null || endDate == null) {
      return '-';
    }

    // Jika di hari yang sama
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return '${DateFormatter.shortDate(startDate)}, '
          '${DateFormatter.time(startDate)} - ${DateFormatter.time(endDate)}';
    }

    // Jika beda hari
    return '${DateFormatter.shortDateTime(startDate)} - '
        '${DateFormatter.shortDateTime(endDate)}';
  }

  String get formattedCreatedAt =>
      createdAt != null ? DateFormatter.timeAgo(createdAt!) : '-';

  String get formattedApprovedAt =>
      approvedAt != null ? DateFormatter.fullDateTime(approvedAt!) : '-';
}
