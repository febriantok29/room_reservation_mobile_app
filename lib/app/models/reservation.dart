import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';

class Reservation extends BaseFirestoreModel {
  static const collectionName = 't_reservations';

  final DocumentReference? userRef;
  final DocumentReference? roomRef;
  final DateTime? startTime;
  final DateTime? endTime;

  /// Waktu asli sebelum di-extend (untuk tracking)
  final DateTime? originalEndTime;

  final int? visitorCount;
  final String? purpose;

  /// Status reservasi (full-otomatis)
  ReservationStatus status;

  /// Alasan pembatalan (jika status = cancelled)
  final String? cancellationReason;

  /// Catatan dari admin (untuk extension, reschedule, dll)
  final String? adminNotes;

  /// Waktu konfirmasi otomatis (saat pertama kali dibuat)
  DateTime? confirmedAt;

  /// Waktu dibatalkan (jika ada)
  final DateTime? cancelledAt;

  /// User yang membatalkan (userId)
  final String? cancelledBy;

  /// Apakah pernah di-reschedule
  final bool wasRescheduled;

  /// Apakah pernah di-extend
  final bool wasExtended;

  Room? room;
  Profile? user;

  @override
  DocumentReference get reference =>
      FirebaseFirestore.instance.collection(collectionName).doc(id);

  Reservation({
    super.id,
    this.userRef,
    this.roomRef,
    this.startTime,
    this.endTime,
    this.originalEndTime,
    this.visitorCount,
    this.purpose,
    this.status = ReservationStatus.confirmed,
    this.cancellationReason,
    this.adminNotes,
    this.confirmedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.wasRescheduled = false,
    this.wasExtended = false,
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    this.room,
    this.user,
  });

  factory Reservation.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      return Reservation();
    }

    return Reservation(
      id: json['id'],
      userRef: json['userId'],
      roomRef: json['roomId'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      originalEndTime: json['originalEndTime'],
      visitorCount: json['visitorCount'],
      purpose: json['purpose'],
      status: json['status'] != null
          ? ReservationStatusExtension.fromString(json['status'])
          : ReservationStatus.confirmed,
      cancellationReason: json['cancellationReason'],
      adminNotes: json['adminNotes'],
      confirmedAt: DateTime.tryParse('${json['confirmedAt']}')?.toLocal(),
      cancelledAt: DateTime.tryParse('${json['cancelledAt']}')?.toLocal(),
      cancelledBy: json['cancelledBy'],
      wasRescheduled: json['wasRescheduled'] ?? false,
      wasExtended: json['wasExtended'] ?? false,
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedBy: json['deletedBy'],
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toLocal(),
      deletedAt: DateTime.tryParse('${json['deletedAt']}')?.toLocal(),
    );
  }

  factory Reservation.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final reservation = Reservation(
      userRef: data['userId'],
      roomRef: data['roomId'],
      startTime: DateFormatter.getDateTime(data['startTime']),
      endTime: DateFormatter.getDateTime(data['endTime']),
      originalEndTime: DateFormatter.getDateTime(data['originalEndTime']),
      visitorCount: data['visitorCount'],
      purpose: data['purpose'],
      status: data['status'] != null
          ? ReservationStatusExtension.fromString(data['status'])
          : ReservationStatus.confirmed,
      cancellationReason: data['cancellationReason'],
      adminNotes: data['adminNotes'],
      confirmedAt: DateFormatter.getDateTime(data['confirmedAt']),
      cancelledAt: DateFormatter.getDateTime(data['cancelledAt']),
      cancelledBy: data['cancelledBy'],
      wasRescheduled: data['wasRescheduled'] ?? false,
      wasExtended: data['wasExtended'] ?? false,
    );

    reservation.setCommonFields(data, documentId);

    return reservation;
  }

  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _timeFormatter = DateFormat('HH:mm');

  String get formattedRange {
    final start = startTime;
    final end = endTime;

    if (start == null || end == null) return '';

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      // Same day
      return '${_dateFormatter.format(start)} ${_timeFormatter.format(start)} - ${_timeFormatter.format(end)}';
    } else {
      // Different days
      return '${_dateFormatter.format(start)} ${_timeFormatter.format(start)} - ${_dateFormatter.format(end)} ${_timeFormatter.format(end)}';
    }
  }

  /// Auto-update status berdasarkan waktu
  /// Dipanggil saat getReservationList() atau detail
  ReservationStatus getComputedStatus() {
    // Jika sudah cancelled, tetap cancelled
    if (status == ReservationStatus.cancelled) {
      return ReservationStatus.cancelled;
    }

    final now = DateTime.now();

    // Jika waktu selesai sudah lewat → COMPLETED
    if (endTime != null && endTime!.isBefore(now)) {
      return ReservationStatus.completed;
    }

    // Jika sudah mulai → ONGOING
    if (startTime != null && startTime!.isBefore(now)) {
      return ReservationStatus.ongoing;
    }

    // Jika 30 menit sebelum mulai → UPCOMING
    if (startTime != null) {
      final diff = startTime!.difference(now);
      if (diff.inMinutes <= 30 && diff.inMinutes >= 0) {
        return ReservationStatus.upcoming;
      }
    }

    // Default: CONFIRMED (menunggu waktu)
    return ReservationStatus.confirmed;
  }

  /// Helper untuk display status dengan warna
  String get statusDisplayName => status.displayName;
  String get statusDescription => status.description;
  String get statusColorHex => status.colorHex;

  /// Membuat salinan objek dengan nilai-nilai yang diperbarui
  Reservation copyWith({
    String? id,
    DocumentReference? userRef,
    DocumentReference? roomRef,
    DateTime? startDateTime,
    DateTime? endDateTime,
    DateTime? originalEndTime,
    int? visitorCount,
    String? purpose,
    ReservationStatus? status,
    String? cancellationReason,
    String? adminNotes,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? cancelledBy,
    bool? wasRescheduled,
    bool? wasExtended,
    String? approvalNote,
    String? approvedBy,
    DateTime? approvedAt,
    Room? room,
    Profile? user,
    DocumentReference? createdBy,
    DocumentReference? updatedBy,
    DocumentReference? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      userRef: userRef ?? this.userRef,
      roomRef: roomRef ?? this.roomRef,
      startTime: startDateTime != null ? startDateTime.toLocal() : startTime,
      endTime: endDateTime != null ? endDateTime.toLocal() : endTime,
      originalEndTime: originalEndTime ?? this.originalEndTime,
      visitorCount: visitorCount ?? this.visitorCount,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      adminNotes: adminNotes ?? this.adminNotes,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      wasRescheduled: wasRescheduled ?? this.wasRescheduled,
      wasExtended: wasExtended ?? this.wasExtended,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      room: room ?? this.room,
      user: user ?? this.user,
    );
  }

  /// Konversi ke Firestore Map
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'userId': userRef,
      'roomId': roomRef,
      'startTime': startTime?.toUtc(),
      'endTime': endTime?.toUtc(),
      'visitorCount': visitorCount,
      'purpose': purpose,
      'status': status.toFirestoreString(),
    };

    // Optional fields
    if (originalEndTime != null) {
      data['originalEndTime'] = originalEndTime?.toUtc();
    }
    if (cancellationReason != null) {
      data['cancellationReason'] = cancellationReason;
    }
    if (adminNotes != null) data['adminNotes'] = adminNotes;
    if (confirmedAt != null) data['confirmedAt'] = confirmedAt?.toUtc();
    if (cancelledAt != null) data['cancelledAt'] = cancelledAt?.toUtc();
    if (cancelledBy != null) data['cancelledBy'] = cancelledBy;
    data['wasRescheduled'] = wasRescheduled;
    data['wasExtended'] = wasExtended;

    // Tambahkan base fields
    final baseFields = toMap();
    data.addAll(baseFields);

    return data;
  }

  /// Validasi model sebelum disimpan ke database
  @override
  void validate() {
    // Validasi required fields
    if (roomRef == null) {
      throw 'Ruangan harus dipilih';
    }

    if (userRef == null) {
      throw 'User ID harus diisi!';
    }

    if (startTime == null) {
      throw 'Waktu mulai harus diisi';
    }

    if (endTime == null) {
      throw 'Waktu selesai harus diisi';
    }

    if (purpose == null || purpose!.isEmpty) {
      throw 'Tujuan reservasi harus diisi';
    }

    // Validasi logika waktu
    final start = startTime;
    final end = endTime;

    if (start != null && end != null) {
      final now = DateTime.now();

      if (start.isBefore(now)) {
        throw 'Waktu mulai tidak boleh di masa lalu';
      }

      if (end.isBefore(start)) {
        throw 'Waktu selesai tidak boleh lebih awal dari waktu mulai';
      }
    }
  }

  /// Set status ke CONFIRMED saat pertama kali dibuat (auto-approve)
  @override
  void prepareForCreate() {
    super.prepareForCreate();
    // Auto-confirm reservation setelah pass CSP validation
    (this).confirmedAt = DateTime.now();
    (this).status = ReservationStatus.confirmed;
  }

  /// Helper method: Cancel reservation
  Reservation cancel(String reason, String userId) {
    if (!status.canBeCancelled) {
      throw 'Reservasi dengan status ${status.displayName} tidak dapat dibatalkan';
    }

    return copyWith(
      status: ReservationStatus.cancelled,
      cancellationReason: reason,
      cancelledAt: DateTime.now(),
      cancelledBy: userId,
    );
  }

  /// Helper method: Reschedule reservation
  Reservation reschedule(DateTime newStart, DateTime newEnd, String adminNote) {
    if (!status.canBeRescheduled) {
      throw 'Reservasi dengan status ${status.displayName} tidak dapat di-reschedule';
    }

    return copyWith(
      startDateTime: newStart,
      endDateTime: newEnd,
      wasRescheduled: true,
      adminNotes: adminNote,
    );
  }

  /// Helper method: Extend reservation (perpanjang waktu)
  Reservation extend(DateTime newEndTime, String adminNote) {
    if (!status.canBeExtended) {
      throw 'Reservasi dengan status ${status.displayName} tidak dapat di-extend';
    }

    return copyWith(
      originalEndTime:
          originalEndTime ?? endTime, // Save original if first extend
      endDateTime: newEndTime,
      wasExtended: true,
      adminNotes: adminNote,
    );
  }

  /// Helper method: Update status based on current time
  /// Should be called when fetching reservations
  Reservation updateStatusIfNeeded() {
    final computedStatus = getComputedStatus();

    if (computedStatus != status) {
      return copyWith(status: computedStatus);
    }

    return this;
  }
}
