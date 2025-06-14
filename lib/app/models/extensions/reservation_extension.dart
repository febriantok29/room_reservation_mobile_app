import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';

extension ReservationX on Reservation {
  /// Format reservation date time menjadi string yang readable
  String get formattedStartTime => DateFormatter.fullDateTime(
        DateTime.parse(startTime ?? ''),
      );

  String get formattedEndTime => DateFormatter.time(
        DateTime.parse(endTime ?? ''),
      );

  String get formattedRange {
    final startDate = DateTime.parse(startTime ?? '');
    final endDate = DateTime.parse(endTime ?? '');
    
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

  String get formattedCreatedAt => createdAt != null 
      ? DateFormatter.timeAgo(createdAt!)
      : '-';

  String get formattedApprovedAt => approvedAt != null
      ? DateFormatter.fullDateTime(approvedAt!)
      : '-';

  /// Status dengan format yang proper (Capitalized)
  String get formattedStatus {
    final rawStatus = status?.toLowerCase() ?? 'pending';
    return rawStatus[0].toUpperCase() + rawStatus.substring(1);
  }

  /// Warna untuk status
  String get statusColor {
    final rawStatus = status?.toLowerCase() ?? 'pending';
    switch (rawStatus) {
      case 'approved':
        return '#4CAF50'; // Green
      case 'rejected':
        return '#F44336'; // Red
      case 'cancelled':
        return '#9E9E9E'; // Grey
      default:
        return '#FF9800'; // Orange for pending
    }
  }
}
