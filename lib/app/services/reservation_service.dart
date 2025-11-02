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
    if (checkOverlap && startDate != null && endDate != null) {
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
      if (checkOverlap && startDate != null && endDate != null) {
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

    /// Generate ID dengan format: RSV-YYYYMMDD-XXXXXX
    ///
    /// Penjelasan format:
    /// - RSV: Prefix untuk identifikasi reservasi (3 karakter)
    /// - YYYYMMDD: Tanggal pembuatan reservasi (8 digit)
    ///   Contoh: 20250102 untuk tanggal 2 Januari 2025
    /// - XXXXXX: Sequential number per hari (6 digit, max 999,999 reservasi/hari)
    ///
    /// Total panjang ID: 3 + 1 + 8 + 1 + 6 = 19 karakter
    /// Contoh: RSV-20250102-000001
    ///
    /// Keunggulan format ini:
    /// 1. Mudah dibaca dan dipahami oleh manusia
    /// 2. Tersortir secara kronologis (berdasarkan tanggal)
    /// 3. Dapat menampung hingga 999,999 reservasi per hari (lebih dari cukup)
    /// 4. Sequential number di-reset setiap hari, menghindari angka yang terlalu besar
    /// 5. Query lebih efisien karena menggunakan range berdasarkan tanggal
    /// 6. Cocok untuk keperluan audit dan reporting (mudah filtering by date)
    ///
    /// Asumsi kapasitas:
    /// - Jika ada 1000 ruangan dan rata-rata 10 reservasi/hari per ruangan
    ///   = 10,000 reservasi/hari (masih sangat jauh dari limit 999,999)
    /// - Bahkan untuk gedung besar dengan 100,000 reservasi/hari masih aman
    final datePrefix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Query untuk mendapatkan jumlah reservasi pada hari yang sama
    // Menggunakan range query untuk performa optimal di Firestore
    final todayPrefix = 'RSV-$datePrefix';
    final tomorrowPrefix =
        'RSV-${now.year}${now.month.toString().padLeft(2, '0')}${(now.day + 1).toString().padLeft(2, '0')}';

    final query = collectionRef
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: todayPrefix)
        .where(FieldPath.documentId, isLessThan: tomorrowPrefix)
        .orderBy(FieldPath.documentId, descending: true)
        // Hanya ambil document terakhir untuk efisiensi
        .limit(1);

    final snapshot = await query.get();

    // Hitung sequence number berikutnya
    int sequenceNumber = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.id;
      // Extract sequence number dari ID terakhir (6 digit terakhir)
      final lastSequence =
          int.tryParse(lastId.substring(lastId.length - 6)) ?? 0;
      sequenceNumber = lastSequence + 1;
    }

    // Format: RSV-YYYYMMDD-XXXXXX (6 digit untuk sequence, max 999,999)
    final generatedId =
        'RSV-$datePrefix-${sequenceNumber.toString().padLeft(6, '0')}';

    final payload = reservation.toFirestore();

    return await client.transaction<Reservation>((
      Transaction transaction,
    ) async {
      // Validasi apakah ID sudah digunakan dengan membaca document secara langsung
      // Transaction.get() hanya mendukung DocumentReference, bukan Query
      final checkDocRef = client.getCollectionRef().doc(generatedId);
      final checkDoc = await transaction.get(checkDocRef);

      String finalId = generatedId;

      // Jika ID sudah ada (race condition), coba dengan increment
      if (checkDoc.exists) {
        // Retry dengan sequence number yang lebih tinggi
        // Dalam praktik, ini sangat jarang terjadi karena sequence sudah dihitung dari query terakhir
        int retrySequence = sequenceNumber + 1;
        bool foundAvailableId = false;

        // Coba maksimal 10 kali untuk mendapatkan ID yang available
        for (int i = 0; i < 10 && !foundAvailableId; i++) {
          final retryId =
              'RSV-$datePrefix-${retrySequence.toString().padLeft(6, '0')}';
          final retryDocRef = client.getCollectionRef().doc(retryId);
          final retryDoc = await transaction.get(retryDocRef);

          if (!retryDoc.exists) {
            finalId = retryId;
            foundAvailableId = true;
          } else {
            retrySequence++;
          }
        }

        if (!foundAvailableId) {
          throw 'Gagal membuat ID reservasi setelah beberapa percobaan. Silakan coba lagi.';
        }
      }

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
