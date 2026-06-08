import 'package:flutter/material.dart';

enum ReservationStatus { pending, approved, rejected, completed, cancelled }

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

  String get colorHex {
    switch (this) {
      case ReservationStatus.pending:
        return '#FF9800';
      case ReservationStatus.approved:
        return '#4CAF50';
      case ReservationStatus.rejected:
        return '#F44336';
      case ReservationStatus.completed:
        return '#117cd4';
      case ReservationStatus.cancelled:
        return '#F44336';
    }
  }

  bool get canBeCancelled {
    return this == ReservationStatus.pending ||
        this == ReservationStatus.approved;
  }

  bool get canBeApproved {
    return this == ReservationStatus.pending;
  }

  bool get canBeRejected {
    return this == ReservationStatus.pending;
  }

  bool get canBeCompleted {
    return this == ReservationStatus.approved;
  }

  bool get isActive {
    return this == ReservationStatus.pending ||
        this == ReservationStatus.approved;
  }

  bool get isFinal {
    return this == ReservationStatus.completed ||
        this == ReservationStatus.cancelled ||
        this == ReservationStatus.rejected;
  }

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

  String toApiString() {
    return name;
  }
}
