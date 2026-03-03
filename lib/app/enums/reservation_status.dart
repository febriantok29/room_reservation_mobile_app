import 'package:flutter/material.dart';

/// Status reservasi dalam sistem full-otomatis
///
/// Flow normal:
/// CONFIRMED → UPCOMING → ONGOING → COMPLETED
///
/// Flow cancellation:
/// CONFIRMED/UPCOMING → CANCELLED
enum ReservationStatus {
  /// Reservasi sudah dikonfirmasi otomatis (setelah pass CSP validation)
  /// - User baru submit dan CSP valid
  /// - Menunggu waktu mulai
  /// - Can be: cancelled, rescheduled (by user/admin)
  confirmed,

  /// 30 menit sebelum waktu mulai
  /// - Auto-transition dari CONFIRMED
  /// - Segera dimulai
  /// - Can be: cancelled (urgent), viewed
  /// - Cannot be: rescheduled (too close)
  upcoming,

  /// Sedang berlangsung (waktu mulai sudah tercapai)
  /// - Auto-transition dari UPCOMING
  /// - Cannot be: cancelled, rescheduled
  /// - Can be: extended (admin only, with CSP check)
  ongoing,

  /// Reservasi selesai normal
  /// - Auto-transition dari ONGOING saat waktu selesai
  /// - Read-only
  completed,

  /// Dibatalkan oleh user atau admin
  /// - Can happen from: CONFIRMED, UPCOMING
  /// - Cannot happen from: ONGOING, COMPLETED
  /// - Reason should be recorded
  cancelled,
}

extension ReservationStatusExtension on ReservationStatus {
  Color get color {
    return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  IconData get icon {
    switch (this) {
      case ReservationStatus.confirmed:
        return Icons.check_circle_outline;
      case ReservationStatus.upcoming:
        return Icons.access_time;
      case ReservationStatus.ongoing:
        return Icons.play_circle_fill;
      case ReservationStatus.completed:
        return Icons.check_circle;
      case ReservationStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Display name untuk UI
  String get displayName {
    switch (this) {
      case ReservationStatus.confirmed:
        return 'Terkonfirmasi';
      case ReservationStatus.upcoming:
        return 'Akan Segera Dimulai';
      case ReservationStatus.ongoing:
        return 'Sedang Berlangsung';
      case ReservationStatus.completed:
        return 'Selesai';
      case ReservationStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  /// Deskripsi status
  String get description {
    switch (this) {
      case ReservationStatus.confirmed:
        return 'Reservasi Anda sudah dikonfirmasi dan menunggu waktu pelaksanaan';
      case ReservationStatus.upcoming:
        return 'Reservasi akan segera dimulai dalam 30 menit';
      case ReservationStatus.ongoing:
        return 'Reservasi sedang berlangsung';
      case ReservationStatus.completed:
        return 'Reservasi telah selesai';
      case ReservationStatus.cancelled:
        return 'Reservasi telah dibatalkan';
    }
  }

  /// Warna untuk UI indicator
  String get colorHex {
    switch (this) {
      case ReservationStatus.confirmed:
        return '#2196F3'; // Blue
      case ReservationStatus.upcoming:
        return '#FF9800'; // Orange
      case ReservationStatus.ongoing:
        return '#4CAF50'; // Green
      case ReservationStatus.completed:
        return '#9E9E9E'; // Grey
      case ReservationStatus.cancelled:
        return '#F44336'; // Red
    }
  }

  /// Apakah bisa dibatalkan
  bool get canBeCancelled {
    return this == ReservationStatus.confirmed ||
        this == ReservationStatus.upcoming;
  }

  /// Apakah bisa di-reschedule
  bool get canBeRescheduled {
    return this == ReservationStatus.confirmed;
  }

  /// Apakah bisa di-extend (perpanjang waktu)
  bool get canBeExtended {
    return this == ReservationStatus.ongoing;
  }

  /// Apakah masih aktif (belum selesai/batal)
  bool get isActive {
    return this == ReservationStatus.confirmed ||
        this == ReservationStatus.upcoming ||
        this == ReservationStatus.ongoing;
  }

  /// Apakah sudah final (tidak bisa diubah)
  bool get isFinal {
    return this == ReservationStatus.completed ||
        this == ReservationStatus.cancelled;
  }

  /// Convert dari string (untuk Firestore)
  static ReservationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'upcoming':
        return ReservationStatus.upcoming;
      case 'ongoing':
        return ReservationStatus.ongoing;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.confirmed; // Default fallback
    }
  }

  /// Convert ke string (untuk Firestore)
  String toFirestoreString() {
    return toString().split('.').last;
  }
}
