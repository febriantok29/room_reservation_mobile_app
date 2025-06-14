import 'package:room_reservation_mobile_app/app/core/network/api_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/api_response.dart';
import 'package:room_reservation_mobile_app/app/models/request/reservation_create_request.dart';
import 'package:room_reservation_mobile_app/app/models/request/reservation_update_request.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';

/// Service untuk mengelola operasi terkait reservasi
class ReservationService {
  static ReservationService? _instance;

  ReservationService._();

  /// Singleton instance
  static Future<ReservationService> getInstance() async {
    _instance ??= ReservationService._();
    return _instance!;
  }

  /// Mendapatkan semua reservasi user yang sedang login
  Future<ApiResponse<List<Reservation>>> getAllReservations({
    int page = 1,
    int limit = 10,
  }) async {
    final builder = await ApiClient.create('Reservation.getAll');

    builder
      ..addQuery('page', page.toString())
      ..addQuery('limit', limit.toString());

    return await builder.get<List<Reservation>>(
      fromJson: (json) => (json as List)
          .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Mendapatkan reservasi berdasarkan ID
  Future<Reservation> getReservationById(String id) async {
    if (id.isEmpty) {
      throw ValidationException('ID reservasi tidak boleh kosong');
    }

    final builder = await ApiClient.create('Reservation.getById');
    builder.addParameter('id', id);

    final response = await builder.get<Reservation>(
      fromJson: Reservation.fromJson,
      errorMessage: 'Gagal memuat detail reservasi',
    );

    final data = response.data;

    if (data == null) {
      throw NotFoundException('Reservasi dengan ID $id tidak ditemukan');
    }

    return data;
  }

  /// Membuat reservasi baru
  Future<Reservation> createReservation({
    required ReservationCreateRequest reservationForm,
  }) async {
    reservationForm.validate();

    _validateReservationTime(
      startDateTime: reservationForm.startTime,
      endDateTime: reservationForm.endTime,
    );

    final reservationData = reservationForm.toJson();

    final builder = await ApiClient.create('Reservation.create');

    final response = await builder.post<Reservation>(
      body: reservationData,
      fromJson: Reservation.fromJson,
      errorMessage: 'Gagal membuat reservasi',
    );

    final data = response.data;

    if (data == null) {
      throw NotFoundException('Reservasi tidak ditemukan setelah dibuat');
    }

    return data;
  }

  /// Update reservasi (hanya untuk reservasi sendiri yang belum disetujui)
  Future<Reservation> updateReservation(
    ReservationUpdateRequest reservationData,
  ) async {
    reservationData.validate();

    // Validasi waktu jika ada update
    _validateReservationTime(
      startDateTime: reservationData.startTime,
      endDateTime: reservationData.endTime,
    );

    final builder = await ApiClient.create('Reservation.update');
    builder.addParameter('id', reservationData.reservationId);

    final response = await builder.put<Reservation>(
      body: reservationData,
      fromJson: Reservation.fromJson,
      errorMessage: 'Gagal mengupdate reservasi',
    );

    final data = response.data;

    if (data == null) {
      throw NotFoundException(
        'Reservasi dengan ID ${reservationData.reservationId} tidak ditemukan',
      );
    }

    return data;
  }

  /// Membatalkan reservasi
  Future<bool> cancelReservation(String id) async {
    if (id.isEmpty) {
      throw ValidationException('ID reservasi tidak boleh kosong');
    }

    final builder = await ApiClient.create('Reservation.delete');
    builder.addParameter('id', id);

    final response = await builder.delete<dynamic>(
      errorMessage: 'Gagal membatalkan reservasi',
    );

    return response.data != null;
  }

  /// Mendapatkan reservasi berdasarkan status
  Future<List<Reservation>> getReservationsByStatus(String status) async {
    final validStatuses = ['pending', 'approved', 'rejected', 'cancelled'];
    if (!validStatuses.contains(status.toLowerCase())) {
      throw ValidationException(
        'Status tidak valid. Status yang valid: ${validStatuses.join(', ')}',
      );
    }

    final builder = await ApiClient.create('Reservation.getAll');
    builder.addQuery('status', status.toLowerCase());

    final response = await builder.get<List<Reservation>>(
      fromJson: (json) => (json as List)
          .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: 'Gagal memuat reservasi berdasarkan status',
    );

    return response.data ?? [];
  }

  /// Mendapatkan reservasi berdasarkan rentang tanggal
  Future<List<Reservation>> getReservationsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (startDate.isAfter(endDate)) {
      throw ValidationException(
        'Tanggal mulai tidak boleh lebih besar dari tanggal selesai',
      );
    }

    final builder = await ApiClient.create('Reservation.getAll');
    builder.addQuery('startDate', startDate.toIso8601String());
    builder.addQuery('endDate', endDate.toIso8601String());

    final response = await builder.get<List<Reservation>>(
      fromJson: (json) => (json as List)
          .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: 'Gagal memuat reservasi berdasarkan tanggal',
    );

    return response.data ?? [];
  }

  /// Mendapatkan reservasi untuk ruangan tertentu
  Future<List<Reservation>> getReservationsByRoom(String roomId) async {
    if (roomId.isEmpty) {
      throw ValidationException('ID ruangan tidak boleh kosong');
    }

    final builder = await ApiClient.create('Reservation.getAll');
    builder.addQuery('roomId', roomId);

    final response = await builder.get<List<Reservation>>(
      fromJson: (json) => (json as List)
          .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: 'Gagal memuat reservasi ruangan',
    );

    return response.data ?? [];
  }

  /// Approve reservasi (hanya untuk admin)
  Future<Reservation> approveReservation(
    String id, {
    String? approvalNote,
  }) async {
    if (id.isEmpty) {
      throw ValidationException('ID reservasi tidak boleh kosong');
    }

    final body = <String, dynamic>{'status': 'approved'};
    if (approvalNote != null && approvalNote.trim().isNotEmpty) {
      body['approvalNote'] = approvalNote.trim();
    }

    final builder = await ApiClient.create('Reservation.update');
    builder.addParameter('id', id);

    final response = await builder.patch<Reservation>(
      body: body,
      fromJson: Reservation.fromJson,
      errorMessage: 'Gagal menyetujui reservasi',
    );

    final data = response.data;

    if (data == null) {
      throw NotFoundException('Reservasi dengan ID $id tidak ditemukan');
    }

    return data;
  }

  /// Reject reservasi (hanya untuk admin)
  Future<Reservation> rejectReservation(
    String id, {
    String? rejectionNote,
  }) async {
    if (id.isEmpty) {
      throw ValidationException('ID reservasi tidak boleh kosong');
    }

    final body = <String, dynamic>{'status': 'rejected'};
    if (rejectionNote != null && rejectionNote.trim().isNotEmpty) {
      body['approvalNote'] = rejectionNote.trim();
    }

    final builder = await ApiClient.create('Reservation.update');
    builder.addParameter('id', id);

    final response = await builder.patch<Reservation>(
      body: body,
      fromJson: Reservation.fromJson,
      errorMessage: 'Gagal menolak reservasi',
    );

    final data = response.data;

    if (data == null) {
      throw NotFoundException('Reservasi dengan ID $id tidak ditemukan');
    }

    return data;
  }

  /// Validasi waktu reservasi
  void _validateReservationTime({
    required DateTime? startDateTime,
    required DateTime? endDateTime,
  }) {
    if (startDateTime == null || endDateTime == null) {
      throw ValidationException('Waktu mulai dan selesai wajib diisi');
    }

    try {
      if (startDateTime.isAfter(endDateTime)) {
        throw ValidationException(
          'Waktu mulai tidak boleh lebih besar dari waktu selesai',
        );
      }

      if (startDateTime.isBefore(DateTime.now())) {
        throw ValidationException('Waktu mulai tidak boleh di masa lalu');
      }

      // Minimal durasi 30 menit
      if (endDateTime.difference(startDateTime).inMinutes < 30) {
        throw ValidationException('Durasi reservasi minimal 30 menit');
      }

      // Maksimal durasi 8 jam
      // if (endDateTime.difference(startDateTime).inHours > 8) {
      //   throw ValidationException('Durasi reservasi maksimal 8 jam');
      // }
    } catch (e) {
      if (e is ValidationException) rethrow;

      throw ValidationException('Format waktu tidak valid');
    }
  }
}
