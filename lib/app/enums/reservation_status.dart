import 'package:flutter/material.dart';

/// Status reservasi sesuai API server
///
/// Flow normal:
/// PENDING → APPROVED → COMPLETED
///
/// Flow rejection:
/// PENDING → REJECTED
///
/// Flow cancellation:
/// PENDING/APPROVED → CANCELLED
enum ReservationStatus {
  /// Reservasi baru dibuat, menunggu persetujuan admin
  pending,

  /// Reservasi disetujui oleh admin
  approved,

  /// Reservasi ditolak oleh admin
  rejected,

  /// Reservasi selesai
  completed,

  /// Reservasi dibatalkan oleh user atau admin
  cancelled,
}

extension ReservationStatusExtension on ReservationStatus {
  Color get color {
    return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  IconData get icon {
    switch (this) {
      case ReservationStatus.pending:
        return Icons.hourglass_empty;
      case ReservationStatus.approved:
        return Icons.check_circle_outline;
      case ReservationStatus.rejected:
        return Icons.block;
      case ReservationStatus.completed:
        return Icons.check_circle;
      case ReservationStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Display name untuk UI (Bahasa Indonesia)
  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'Menunggu Persetujuan';
      case ReservationStatus.approved:
        return 'Disetujui';
      case ReservationStatus.rejected:
        return 'Ditolak';
      case ReservationStatus.completed:
        return 'Selesai';
      case ReservationStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  /// Deskripsi status
  String get description {
    switch (this) {
      case ReservationStatus.pending:
        return 'Reservasi menunggu persetujuan dari admin';
      case ReservationStatus.approved:
        return 'Reservasi telah disetujui dan siap digunakan';
      case ReservationStatus.rejected:
        return 'Reservasi ditolak oleh admin';
      case ReservationStatus.completed:
        return 'Reservasi telah selesai';
      case ReservationStatus.cancelled:
        return 'Reservasi telah dibatalkan';
    }
  }

  /// Warna untuk UI indicator
  String get colorHex {
    switch (this) {
      case ReservationStatus.pending:
        return '#FF9800'; // Orange
      case ReservationStatus.approved:
        return '#4CAF50'; // Green
      case ReservationStatus.rejected:
        return '#F44336'; // Red
      case ReservationStatus.completed:
        return '#9E9E9E'; // Grey
      case ReservationStatus.cancelled:
        return '#F44336'; // Red
    }
  }

  /// Apakah bisa dibatalkan
  bool get canBeCancelled {
    return this == ReservationStatus.pending ||
        this == ReservationStatus.approved;
  }

  /// Apakah bisa di-approve (admin only)
  bool get canBeApproved {
    return this == ReservationStatus.pending;
  }

  /// Apakah bisa di-reject (admin only)
  bool get canBeRejected {
    return this == ReservationStatus.pending;
  }

  /// Apakah bisa di-complete
  bool get canBeCompleted {
    return this == ReservationStatus.approved;
  }

  /// Apakah masih aktif (belum selesai/batal/ditolak)
  bool get isActive {
    return this == ReservationStatus.pending ||
        this == ReservationStatus.approved;
  }

  /// Apakah sudah final (tidak bisa diubah)
  bool get isFinal {
    return this == ReservationStatus.completed ||
        this == ReservationStatus.cancelled ||
        this == ReservationStatus.rejected;
  }

  /// Convert dari string API
  static ReservationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ReservationStatus.pending;
      case 'approved':
        return ReservationStatus.approved;
      case 'rejected':
        return ReservationStatus.rejected;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.pending;
    }
  }

  /// Convert ke string untuk API
  String toApiString() {
    return name;
  }
}
