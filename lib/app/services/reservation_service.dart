import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
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
    DateTime? startDate,
    DateTime? endDate,
    bool showDeleted = false,
  }) async {
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw 'Tanggal mulai tidak boleh lebih besar dari tanggal selesai.';
    }

    final client = await FirestoreClient.create(Reservation.collectionName);

    Query<Map<String, dynamic>> query = client.getCollectionRef();

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (startDate != null) {
      final startTimestamp = Timestamp.fromDate(startDate);

      query = query.where('startTime', isGreaterThanOrEqualTo: startTimestamp);
    }

    if (endDate != null) {
      final endTimestamp = Timestamp.fromDate(endDate);

      query = query.where('endTime', isLessThanOrEqualTo: endTimestamp);
    }

    if (!showDeleted) {
      query = query.where(BaseFirestoreModel.deletedAtField, isEqualTo: null);
    }

    final response = await query.get();

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
      final roomRef = reservation.roomRef;
      if (roomRef == null || roomRef.id.isEmpty) {
        continue;
      }

      final roomId = roomRef.id;

      final room = rooms.where((room) => room.id == roomId);

      if (room.isNotEmpty) {
        reservation.room = room.first;
      }
    }

    final userIds = Set<String>.from(
      reservations.map((res) => res.userRef?.id),
    );

    final users = await UserService.getUserByDocIds(userIds);

    for (final reservation in reservations) {
      final user = users.where((user) => user.id == reservation.userRef?.id);

      if (user.isNotEmpty) {
        reservation.user = user.first;
      }
    }

    return reservations;
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
    if (reservation.startTime != null && reservation.endTime != null) {
      _validateReservationTime(
        startDateTime: reservation.startTime!,
        endDateTime: reservation.endTime!,
      );
    }

    // Simpan ke Firestore
    final client = await FirestoreClient.create(Reservation.collectionName);

    final payload = reservation.toFirestore();

    return await client.transaction<Reservation>((
      Transaction transaction,
    ) async {
      final newDocRef = client.getCollectionRef().doc();
      transaction.set(newDocRef, payload);
      return reservation.copyWith(id: newDocRef.id);
    });

    // final docRef = await client.add(payload);
    //
    // // Return reservation dengan ID baru
    // return reservation.copyWith(id: docRef.id);
  }

  /// Update reservasi (hanya untuk reservasi sendiri yang belum disetujui)
  Future<Reservation> updateReservation(Reservation reservation) async {
    if (reservation.id == null || reservation.id!.isEmpty) {
      throw ValidationException('ID reservasi tidak boleh kosong');
    }

    // Validasi data
    reservation.validate();

    // Validasi waktu jika ada
    if (reservation.startTime != null && reservation.endTime != null) {
      _validateReservationTime(
        startDateTime: reservation.startTime!,
        endDateTime: reservation.endTime!,
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

    // Update status menjadi CANCELLED
    final updatedReservation = reservation.copyWith(
      // status: Reservation.statusCancelled,
    );

    // Prepare for update
    updatedReservation.prepareForUpdate();

    // Simpan ke Firestore
    final payload = updatedReservation.toFirestore();
    await client.update(id, payload);

    return true;
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
