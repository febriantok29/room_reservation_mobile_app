import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/core/network/api_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/api_response.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';
import 'package:room_reservation_mobile_app/app/services/user_service.dart';

/// Service untuk mengelola operasi terkait reservasi
class ReservationService {
  static ReservationService? _instance;

  ReservationService._();

  /// Singleton instance
  static ReservationService getInstance() {
    _instance ??= ReservationService._();
    return _instance!;
  }

  Future<List<Reservation>> getReservationList({
    DocumentReference? userId,
  }) async {
    final client = await FirestoreClient.create(Reservation.collectionName);

    QuerySnapshot<Map<String, dynamic>> response;
    if (userId != null) {
      response = await client.query(field: 'userId', isEqualTo: userId);
    } else {
      response = await client.getAll();
    }

    final reservations = <Reservation>[];

    for (final doc in response.docs) {
      if (!doc.exists) continue;

      final data = doc.data();

      final reservation = Reservation.fromFirestore(data, doc.id);

      reservations.add(reservation);
    }

    final roomIds = reservations
        .where((res) => res.roomRef != null)
        .map((res) => res.roomRef!.id)
        .toSet();

    final roomService = RoomService.getInstance();
    final rooms = await roomService.getByIds(roomIds);

    for (final reservation in reservations) {
      if (reservation.roomRef == null || reservation.roomRef!.id.isEmpty) {
        continue;
      }

      reservation.room = rooms.firstWhere(
        (room) => room.id == reservation.roomRef?.id,
        orElse: () => Room(),
      );
    }

    final userIds = Set<String>.from(
      reservations.map((res) => res.userRef?.id),
    );

    final users = await UserService.getUserByEmployeeIds(userIds);

    for (final reservation in reservations) {
      final user = users.firstWhere(
        (user) => user.id == reservation.userRef?.id,
        orElse: () => Profile(),
      );

      reservation.user = user;
    }

    return reservations;
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

    // Ambil dari Firestore
    final client = await FirestoreClient.create(Reservation.collectionName);

    final doc = await client.get(id);

    if (!doc.exists) {
      throw NotFoundException('Reservasi dengan ID $id tidak ditemukan');
    }

    final data = doc.data() ?? {};
    final reservation = Reservation.fromFirestore(data, id);

    // Ambil data ruangan dan user jika perlu
    if (reservation.roomRef != null && reservation.roomRef!.id.isNotEmpty) {
      final roomService = RoomService.getInstance();
      try {
        final room = await roomService.getRoomByDoc(reservation.roomRef!);
        reservation.room = room;
      } catch (_) {}
    }

    final userRef = reservation.userRef;
    if (userRef != null) {
      try {
        final user = await UserService.getProfileByDoc(userRef);
        reservation.user = user;
      } catch (_) {}
    }

    return reservation;
  }

  /// Membuat reservasi baru
  Future<Reservation> createReservation(Reservation reservation) async {
    // Validasi data
    reservation.validate();

    // Validasi waktu reservasi
    if (reservation.startDateTime != null && reservation.endDateTime != null) {
      _validateReservationTime(
        startDateTime: reservation.startDateTime!,
        endDateTime: reservation.endDateTime!,
      );
    }

    // Simpan ke Firestore
    final client = await FirestoreClient.create(Reservation.collectionName);

    final payload = reservation.toFirestore();

    final docRef = await client.add(payload);

    // Return reservation dengan ID baru
    return reservation.copyWith(id: docRef.id);
  }

  /// Update reservasi (hanya untuk reservasi sendiri yang belum disetujui)
  Future<Reservation> updateReservation(Reservation reservation) async {
    if (reservation.id == null || reservation.id!.isEmpty) {
      throw ValidationException('ID reservasi tidak boleh kosong');
    }

    // Validasi data
    reservation.validate();

    // Validasi waktu jika ada
    if (reservation.startDateTime != null && reservation.endDateTime != null) {
      _validateReservationTime(
        startDateTime: reservation.startDateTime!,
        endDateTime: reservation.endDateTime!,
      );
    }

    // Validasi status - hanya bisa update jika masih pending
    if (reservation.status != null &&
        reservation.status != Reservation.statusPending) {
      throw ValidationException(
        'Hanya reservasi dengan status PENDING yang dapat diupdate',
      );
    }

    // Simpan ke Firestore
    final client = await FirestoreClient.create(Reservation.collectionName);

    final payload = reservation.toFirestore();

    await client.update(reservation.id!, payload);

    return reservation;
  }

  /// Membatalkan reservasi
  Future<bool> cancelReservation(String id, String userId) async {
    if (id.isEmpty) {
      throw ValidationException('ID reservasi tidak boleh kosong');
    }

    // Ambil reservasi yang akan dibatalkan
    final client = await FirestoreClient.create(Reservation.collectionName);

    final doc = await client.get(id);

    if (!doc.exists) {
      throw NotFoundException('Reservasi tidak ditemukan');
    }

    final data = doc.data() ?? {};
    final reservation = Reservation.fromFirestore(data, id);

    // Validasi status - hanya bisa dibatalkan jika masih pending atau approved
    if (reservation.status != Reservation.statusPending &&
        reservation.status != Reservation.statusApproved) {
      throw ValidationException(
        'Hanya reservasi dengan status PENDING atau APPROVED yang dapat dibatalkan',
      );
    }

    // Update status menjadi CANCELLED
    final updatedReservation = reservation.copyWith(
      status: Reservation.statusCancelled,
    );

    // Prepare for update
    updatedReservation.prepareForUpdate();

    // Simpan ke Firestore
    final payload = updatedReservation.toFirestore();
    await client.update(id, payload);

    return true;
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
