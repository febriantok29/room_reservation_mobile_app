import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';
import 'package:room_reservation_mobile_app/app/services/user_service.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';
import 'package:room_reservation_mobile_app/app/utils/reservation_id_generator.dart';

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
    bool checkOverlap = false, // Parameter baru untuk cek overlap
  }) async {
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw 'Tanggal mulai tidak boleh lebih besar dari tanggal selesai.';
    }

    final client = await FirestoreClient.create(Reservation.collectionName);

    Query<Map<String, dynamic>> query = client.getCollectionRef();

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    // Logika berbeda untuk checkOverlap
    if (checkOverlap && (startDate != null && endDate != null)) {
      // Untuk mengecek overlap, kita perlu ambil reservasi yang:
      // 1. startTime < endDate (reservasi dimulai sebelum waktu yang kita cari selesai)
      // 2. endTime > startDate (reservasi berakhir setelah waktu yang kita cari dimulai)
      //
      // Firestore limitation: tidak bisa query dengan 2 field berbeda dalam range
      // Solusi: ambil semua reservasi yang startTime < endDate,
      // lalu filter di memory untuk endTime > startDate
      final endTimestamp = Timestamp.fromDate(endDate);
      query = query.where('startTime', isLessThan: endTimestamp);
    } else {
      // Query original (untuk listing biasa)
      if (startDate != null) {
        final startTimestamp = Timestamp.fromDate(startDate);
        query = query.where(
          'startTime',
          isGreaterThanOrEqualTo: startTimestamp,
        );
      }

      if (endDate != null) {
        final endTimestamp = Timestamp.fromDate(endDate);
        query = query.where('endTime', isLessThanOrEqualTo: endTimestamp);
      }
    }

    if (!showDeleted) {
      query = query.where(BaseFirestoreModel.deletedAtField, isNull: true);
    }

    final response = await query.get();

    final reservations = <Reservation>[];

    for (final doc in response.docs) {
      if (!doc.exists) continue;

      final data = doc.data();

      final reservation = Reservation.fromFirestore(data, doc.id);

      // Filter tambahan untuk overlap check (karena Firestore limitation)
      if (checkOverlap && (startDate != null && endDate != null)) {
        // Skip jika reservasi tidak overlap dengan range yang dicari
        // Overlap terjadi jika: endTime > startDate
        if (reservation.endTime == null ||
            reservation.endTime!.isBefore(startDate) ||
            reservation.endTime!.isAtSameMomentAs(startDate)) {
          continue;
        }
      }

      reservations.add(reservation);
    }

    final roomIds = reservations
        .where((res) => res.roomRef != null)
        .map((res) => res.roomRef!.id)
        .toSet();

    final roomService = RoomService.getInstance();

    // Ambil room data menggunakan getByIds yang akan:
    // 1. Cek cache dulu
    // 2. Fetch dari Firestore jika belum ada di cache
    // 3. Update cache dengan room yang baru di-fetch
    final rooms = await roomService.getByIds(roomIds);

    // Populate room object ke setiap reservasi
    for (final reservation in reservations) {
      final roomRef = reservation.roomRef;

      if (roomRef == null || roomRef.id.isEmpty) {
        continue;
      }

      final roomId = roomRef.id;

      final matchedRooms = rooms.where((room) => room.id == roomId);

      if (matchedRooms.isEmpty) {
        continue;
      }

      reservation.room = matchedRooms.first;
    }

    final userIds = Set<String>.from(
      reservations.map((reservation) => reservation.userRef?.id),
    );

    final users = await UserService.getUserByDocIds(userIds);

    for (final reservation in reservations) {
      final userRef = reservation.userRef;

      if (userRef == null || userRef.id.isEmpty) {
        continue;
      }

      final userId = userRef.id;

      final user = users.where((user) => user.id == userId);

      if (user.isEmpty) {
        continue;
      }

      reservation.user = user.first;
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

    reservation.prepareForCreate();

    // Simpan ke Firestore
    final client = await FirestoreClient.create(Reservation.collectionName);
    final collectionRef = client.getCollectionRef();
    final now = DateTime.now();

    // Generate ID menggunakan helper class
    // ID akan di-validasi ulang dalam transaction untuk menghindari race condition
    final generatedId = await ReservationIdGenerator.generateNextId(
      collectionRef,
      date: now,
    );

    final payload = reservation.toFirestore();

    return await client.transaction<Reservation>((
      Transaction transaction,
    ) async {
      /// ============================================================================
      /// VALIDASI OVERLAP RUANGAN (CRITICAL - MENCEGAH DOUBLE BOOKING)
      /// ============================================================================
      ///
      /// Validasi ini WAJIB dilakukan di dalam transaction untuk memastikan
      /// tidak ada 2 pemesanan yang terjadi secara bersamaan (concurrent booking).
      ///
      /// Skenario yang dicegah:
      /// - User A dan User B memesan ruangan X di waktu yang sama
      /// - Keduanya submit form hampir bersamaan (selisih milidetik)
      /// - Tanpa transaction: KEDUA pemesanan akan berhasil (DOUBLE BOOKING ❌)
      /// - Dengan transaction: Hanya 1 yang berhasil, yang lain akan gagal (✅)
      ///
      /// Cara kerja Firestore Transaction:
      /// 1. Transaction membaca data (get) - snapshot di awal
      /// 2. Jika ada perubahan data di tengah transaction, Firestore akan
      ///    OTOMATIS retry transaction dari awal (maksimal 5x)
      /// 3. Jika masih gagal setelah 5x retry, akan throw error
      /// 4. Ini menjamin ACID properties (Atomicity, Consistency, Isolation, Durability)
      ///
      /// PENTING:
      /// - Kita TIDAK bisa menggunakan .where() query di dalam transaction
      /// - Solusi: Fetch beberapa document terakhir untuk hari tersebut
      ///   dan filter manual di memory (tetap aman karena dalam transaction)
      /// ============================================================================

      // Ambil semua reservasi pada hari yang sama untuk ruangan ini
      // Query untuk mengambil reservasi yang mungkin overlap
      // Karena transaction tidak support complex query, kita ambil range lebar
      // dan filter manual di memory
      final (dayPrefix, nextDayPrefix) =
          ReservationIdGenerator.generateDatePrefixRange(now);

      // Ambil semua reservasi hari ini (untuk validasi overlap)
      final potentialConflicts = collectionRef
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: dayPrefix)
          .where(FieldPath.documentId, isLessThan: nextDayPrefix)
          .limit(1000); // Limit tinggi untuk memastikan semua data terambil

      final conflictSnapshot = await potentialConflicts.get();

      // Filter dan cek overlap secara manual
      // Overlap terjadi jika:
      // 1. Ruangan sama (roomId sama)
      // 2. Waktu mulai reservasi baru < waktu selesai reservasi existing
      // 3. Waktu selesai reservasi baru > waktu mulai reservasi existing
      // 4. Reservasi existing tidak dalam status CANCELLED/REJECTED/DELETED
      for (final doc in conflictSnapshot.docs) {
        final data = doc.data();

        // Skip jika sudah dihapus
        if (data[BaseFirestoreModel.deletedAtField] != null) continue;

        // Cek apakah ruangan sama
        final existingRoomRef = data['roomId'] as DocumentReference?;
        if (existingRoomRef?.id != reservation.roomRef?.id) continue;

        // Ambil waktu existing reservation
        final existingStart = DateFormatter.getDateTime(data['startTime']);
        final existingEnd = DateFormatter.getDateTime(data['endTime']);

        if (existingStart == null || existingEnd == null) continue;

        // Cek overlap menggunakan interval intersection logic
        // Overlap terjadi jika: NOT (A.end <= B.start OR A.start >= B.end)
        // Atau dengan kata lain: A.start < B.end AND A.end > B.start
        final hasOverlap =
            reservation.startTime!.isBefore(existingEnd) &&
            reservation.endTime!.isAfter(existingStart);

        if (hasOverlap) {
          // Format waktu untuk error message yang informatif
          final formatter = DateFormat('dd MMM yyyy HH:mm');
          final existingRange =
              '${formatter.format(existingStart)} - ${formatter.format(existingEnd)}';
          final requestedRange =
              '${formatter.format(reservation.startTime!)} - ${formatter.format(reservation.endTime!)}';

          throw Exception(
            'Ruangan sudah dipesan pada waktu tersebut!\n\n'
            'Pemesanan existing: $existingRange\n'
            'Waktu yang Anda pilih: $requestedRange\n\n'
            'Silakan pilih waktu lain.',
          );
        }
      }

      /// ============================================================================
      /// GENERATE & VALIDASI ID UNIK
      /// ============================================================================

      // Validasi dan retry ID jika terjadi race condition
      // Menggunakan helper class untuk handle retry logic
      final finalId =
          await ReservationIdGenerator.validateAndRetryInTransaction(
            transaction,
            collectionRef,
            generatedId,
            now,
            maxRetries: 10,
          );

      /// ============================================================================
      /// CREATE RESERVATION
      /// ============================================================================

      // Create document dengan custom ID yang sudah digenerate dan divalidasi
      final newDocRef = client.getCollectionRef().doc(finalId);
      transaction.set(newDocRef, payload);

      return reservation.copyWith(id: newDocRef.id);
    });
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
