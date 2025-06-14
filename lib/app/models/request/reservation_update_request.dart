import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';

class ReservationUpdateRequest {
  final String reservationId; // Required for update
  String? roomId;
  DateTime? startTime;
  DateTime? endTime;
  String? purpose;
  int? visitorCount;

  ReservationUpdateRequest({
    required this.reservationId,
    this.roomId,
    this.startTime,
    this.endTime,
    this.purpose,
    this.visitorCount,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    // Only include fields that are not null
    if (roomId != null) map['roomId'] = roomId;
    if (startTime != null) map['startTime'] = startTime?.toIso8601String();
    if (endTime != null) map['endTime'] = endTime?.toIso8601String();
    if (purpose != null) map['purpose'] = purpose;
    if (visitorCount != null) map['visitorCount'] = visitorCount;

    return map;
  }

  void validate() {
    if (reservationId.isEmpty) {
      throw ValidationException('ID reservasi wajib diisi');
    }

    // Validate only provided fields
    if (roomId != null && roomId!.isEmpty) {
      throw ValidationException('ID ruangan tidak valid');
    }

    if (purpose != null && purpose!.trim().isEmpty) {
      throw ValidationException('Tujuan reservasi tidak boleh kosong');
    }

    if (visitorCount != null && visitorCount! < 1) {
      throw ValidationException('Jumlah pengunjung minimal 1 orang');
    }

    // Validate time if either is provided
    if (startTime != null && endTime == null) {
      throw ValidationException(
        'Waktu selesai harus diisi jika mengubah waktu mulai',
      );
    }

    if (endTime != null && startTime == null) {
      throw ValidationException(
        'Waktu mulai harus diisi jika mengubah waktu selesai',
      );
    }
  }
}
