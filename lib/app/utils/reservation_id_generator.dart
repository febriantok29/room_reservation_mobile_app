import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class untuk generate dan validasi Reservation Document ID
///
/// Format ID: RSV-YYYYMMDD-XX
/// Contoh: RSV-20250104-01
///
/// Penjelasan format:
/// - RSV: Prefix untuk identifikasi reservasi (3 karakter)
/// - YYYYMMDD: Tanggal pembuatan reservasi (8 digit)
/// - XX: Sequential number per hari (2 digit, max 99 reservasi/hari)
///
/// Total panjang: 15 karakter
///
/// Keunggulan:
/// 1. Mudah dibaca dan dipahami manusia
/// 2. Tersortir secara kronologis (berdasarkan tanggal)
/// 3. Dapat menampung hingga 99 reservasi per hari (cukup untuk kebutuhan normal)
/// 4. Sequential number di-reset setiap hari
/// 5. Query lebih efisien (range berdasarkan tanggal)
/// 6. Cocok untuk audit dan reporting
/// 7. ID lebih pendek dan mudah diingat
class ReservationIdGenerator {
  /// Prefix untuk semua reservation ID
  static const String prefix = 'RSV';

  /// Panjang sequence number (dalam digit)
  static const int sequenceLength = 2;

  /// Maximum reservasi per hari (99)
  static const int maxReservationsPerDay = 99;

  /// Generate prefix range untuk query hari tertentu
  ///
  /// Returns: (todayPrefix, tomorrowPrefix)
  /// Example: ('RSV-20250104', 'RSV-20250105')
  static (String, String) generateDatePrefixRange(DateTime date) {
    final datePrefix = _formatDatePrefix(date);
    final todayPrefix = '$prefix-$datePrefix';

    // Hitung prefix hari berikutnya untuk range query
    final tomorrow = date.add(const Duration(days: 1));
    final tomorrowDatePrefix = _formatDatePrefix(tomorrow);
    final tomorrowPrefix = '$prefix-$tomorrowDatePrefix';

    return (todayPrefix, tomorrowPrefix);
  }

  /// Generate ID baru berdasarkan last sequence number
  ///
  /// [date] - Tanggal reservasi (default: DateTime.now())
  /// [lastSequence] - Sequence number terakhir (default: 0)
  ///
  /// Returns: ID baru dengan format RSV-YYYYMMDD-XX
  static String generateId({DateTime? date, int lastSequence = 0}) {
    final targetDate = date ?? DateTime.now();
    final datePrefix = _formatDatePrefix(targetDate);
    final nextSequence = lastSequence + 1;

    // Validasi: pastikan tidak melebihi max per hari
    if (nextSequence > maxReservationsPerDay) {
      throw 'Maximum reservasi per hari ($maxReservationsPerDay) telah tercapai.\n'
          'Tidak dapat membuat reservasi baru untuk tanggal ini.';
    }

    final sequenceStr = nextSequence.toString().padLeft(sequenceLength, '0');
    return '$prefix-$datePrefix-$sequenceStr';
  }

  /// Extract sequence number dari reservation ID
  ///
  /// [reservationId] - ID reservasi (format: RSV-YYYYMMDD-XX)
  ///
  /// Returns: Sequence number (int), atau 0 jika parsing gagal
  ///
  /// Example:
  /// ```dart
  /// extractSequenceNumber('RSV-20250104-42') // returns 42
  /// ```
  static int extractSequenceNumber(String reservationId) {
    if (!isValidFormat(reservationId)) {
      return 0;
    }

    try {
      // Ambil 2 digit terakhir
      final sequenceStr = reservationId.substring(
        reservationId.length - sequenceLength,
      );
      return int.tryParse(sequenceStr) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Extract tanggal dari reservation ID
  ///
  /// [reservationId] - ID reservasi (format: RSV-YYYYMMDD-XX)
  ///
  /// Returns: DateTime atau null jika parsing gagal
  ///
  /// Example:
  /// ```dart
  /// extractDate('RSV-20250104-01') // returns DateTime(2025, 1, 4)
  /// ```
  static DateTime? extractDate(String reservationId) {
    if (!isValidFormat(reservationId)) {
      return null;
    }

    try {
      // Format: RSV-YYYYMMDD-XX
      // Extract YYYYMMDD (index 4-11)
      final dateStr = reservationId.substring(4, 12);
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Validasi format reservation ID
  ///
  /// [reservationId] - ID yang akan divalidasi
  ///
  /// Returns: true jika format valid
  ///
  /// Valid format: RSV-YYYYMMDD-XX
  /// - Total length: 15 characters
  /// - Prefix: RSV
  /// - Date: 8 digits (YYYYMMDD)
  /// - Sequence: 2 digits (01-99)
  static bool isValidFormat(String reservationId) {
    if (reservationId.length != 15) return false;
    if (!reservationId.startsWith('$prefix-')) return false;

    // Check format dengan regex
    final regex = RegExp(r'^RSV-\d{8}-\d{2}$');
    return regex.hasMatch(reservationId);
  }

  /// Query untuk mendapatkan last sequence number dari Firestore
  ///
  /// [collectionRef] - Collection reference untuk reservasi
  /// [date] - Tanggal yang akan dicek (default: DateTime.now())
  ///
  /// Returns: Last sequence number untuk hari tersebut
  static Future<int> getLastSequenceNumber(
    CollectionReference<Map<String, dynamic>> collectionRef, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final (todayPrefix, tomorrowPrefix) = generateDatePrefixRange(targetDate);

    final query = collectionRef
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: todayPrefix)
        .where(FieldPath.documentId, isLessThan: tomorrowPrefix)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(1);

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      return 0; // Belum ada reservasi hari ini
    }

    final lastId = snapshot.docs.first.id;
    return extractSequenceNumber(lastId);
  }

  /// Generate ID dengan auto-increment dari database
  ///
  /// [collectionRef] - Collection reference untuk reservasi
  /// [date] - Tanggal reservasi (default: DateTime.now())
  ///
  /// Returns: ID baru yang sudah di-increment
  static Future<String> generateNextId(
    CollectionReference<Map<String, dynamic>> collectionRef, {
    DateTime? date,
  }) async {
    final lastSequence = await getLastSequenceNumber(collectionRef, date: date);
    return generateId(date: date, lastSequence: lastSequence);
  }

  /// Validasi ID dalam transaction dengan retry mechanism
  ///
  /// [transaction] - Firestore transaction
  /// [collectionRef] - Collection reference
  /// [initialId] - ID awal yang di-generate
  /// [date] - Tanggal reservasi
  /// [maxRetries] - Maksimal percobaan (default: 10)
  ///
  /// Returns: ID yang valid dan available
  ///
  /// Throws: Exception jika semua retry gagal
  static Future<String> validateAndRetryInTransaction(
    Transaction transaction,
    CollectionReference<Map<String, dynamic>> collectionRef,
    String initialId,
    DateTime date, {
    int maxRetries = 10,
  }) async {
    // Cek ID awal
    final initialDocRef = collectionRef.doc(initialId);
    final initialDoc = await transaction.get(initialDocRef);

    if (!initialDoc.exists) {
      return initialId; // ID available
    }

    // ID sudah digunakan, coba increment
    final initialSequence = extractSequenceNumber(initialId);
    int retrySequence = initialSequence + 1;

    for (int i = 0; i < maxRetries; i++) {
      final retryId = generateId(date: date, lastSequence: retrySequence - 1);
      final retryDocRef = collectionRef.doc(retryId);
      final retryDoc = await transaction.get(retryDocRef);

      if (!retryDoc.exists) {
        return retryId; // ID available
      }

      retrySequence++;
    }

    // Semua retry gagal
    throw 'Gagal membuat ID reservasi setelah $maxRetries percobaan.\n'
        'Sistem sedang sibuk, silakan coba lagi dalam beberapa saat.';
  }

  /// Format date menjadi YYYYMMDD
  static String _formatDatePrefix(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Get statistics untuk debugging/monitoring
  ///
  /// [collectionRef] - Collection reference
  /// [date] - Tanggal yang akan dicek
  ///
  /// Returns: Map dengan informasi statistik
  static Future<Map<String, dynamic>> getStatistics(
    CollectionReference<Map<String, dynamic>> collectionRef,
    DateTime date,
  ) async {
    final (todayPrefix, tomorrowPrefix) = generateDatePrefixRange(date);

    final query = collectionRef
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: todayPrefix)
        .where(FieldPath.documentId, isLessThan: tomorrowPrefix);

    final snapshot = await query.get();

    return {
      'date': date.toString().split(' ')[0],
      'totalReservations': snapshot.docs.length,
      'maxPerDay': maxReservationsPerDay,
      'remainingSlots': maxReservationsPerDay - snapshot.docs.length,
      'utilizationPercentage':
          (snapshot.docs.length / maxReservationsPerDay * 100).toStringAsFixed(
            2,
          ),
    };
  }
}
