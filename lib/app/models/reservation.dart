import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';

class Reservation extends BaseFirestoreModel {
  static const collectionName = 't_reservations';

  // Status reservasi
  static const String statusPending = 'PENDING';
  static const String statusApproved = 'APPROVED';
  static const String statusRejected = 'REJECTED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusCompleted = 'COMPLETED';

  final DocumentReference? userRef;
  final DocumentReference? roomRef;
  final String? startTime;
  final String? endTime;
  final int? visitorCount;
  final String? purpose;
  final String? status;
  final String? approvalNote;
  final String? approvedBy;
  final DateTime? approvedAt;

  Room? room;
  Profile? user;

  @override
  DocumentReference get reference => FirebaseFirestore.instance
      .collection(collectionName)
      .doc(id);

  Reservation({
    super.id,
    this.userRef,
    this.roomRef,
    this.startTime,
    this.endTime,
    this.visitorCount,
    this.approvalNote,
    this.purpose,
    this.status,
    this.approvedBy,
    this.approvedAt,
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
      visitorCount: json['visitorCount'],
      approvalNote: json['approvalNote'],
      purpose: json['purpose'],
      status: json['status'],
      approvedBy: json['approvedBy'],
      approvedAt: DateTime.tryParse('${json['approvedAt']}')?.toLocal(),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedBy: json['deletedBy'],
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toLocal(),
      deletedAt: DateTime.tryParse('${json['deletedAt']}')?.toLocal(),
      // room: json['room'] != null ? Room.fromJson(json['room']) : null,
      // user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  factory Reservation.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final reservation = Reservation(
      userRef: data['userId'],
      roomRef: data['roomId'],
      startTime: data['startTime'],
      endTime: data['endTime'],
      visitorCount: data['visitorCount'],
      approvalNote: data['approvalNote'],
      purpose: data['purpose'],
      status: data['status'],
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null
          ? DateTime.tryParse('${data['approvedAt']}')?.toLocal()
          : null,
    );

    reservation.setCommonFields(data, documentId);

    return reservation;
  }

  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _timeFormatter = DateFormat('HH:mm');

  String get formattedRange {
    if (startTime == null || endTime == null) return '';

    final start = DateTime.parse(startTime!);
    final end = DateTime.parse(endTime!);

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

  /// Mendapatkan DateTime dari string startTime
  DateTime? get startDateTime =>
      startTime != null ? DateTime.parse(startTime!) : null;

  /// Mendapatkan DateTime dari string endTime
  DateTime? get endDateTime =>
      endTime != null ? DateTime.parse(endTime!) : null;

  /// Membuat salinan objek dengan nilai-nilai yang diperbarui
  Reservation copyWith({
    String? id,
    DocumentReference? userRef,
    DocumentReference? roomRef,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? visitorCount,
    String? approvalNote,
    String? purpose,
    String? status,
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
      startTime: startDateTime != null
          ? startDateTime.toIso8601String()
          : startTime,
      endTime: endDateTime != null
          ? endDateTime.toIso8601String()
          : endTime,
      visitorCount: visitorCount ?? this.visitorCount,
      approvalNote: approvalNote ?? this.approvalNote,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
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
      'startTime': startTime,
      'endTime': endTime,
      'visitorCount': visitorCount,
      'purpose': purpose,
      'status': status ?? statusPending,
    };

    if (approvedBy != null) data['approvedBy'] = approvedBy;
    if (approvedAt != null) data['approvedAt'] = approvedAt?.toIso8601String();
    if (approvalNote != null) data['approvalNote'] = approvalNote;

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
      throw ValidationException('Ruangan harus dipilih');
    }

    if (userRef == null) {
      throw ValidationException('User ID harus diisi!');
    }

    if (startTime == null || startTime!.isEmpty) {
      throw ValidationException('Waktu mulai harus diisi');
    }

    if (endTime == null || endTime!.isEmpty) {
      throw ValidationException('Waktu selesai harus diisi');
    }

    if (purpose == null || purpose!.isEmpty) {
      throw ValidationException('Tujuan reservasi harus diisi');
    }

    // Validasi logika waktu
    final start = startDateTime;
    final end = endDateTime;

    if (start != null && end != null) {
      final now = DateTime.now();

      if (start.isBefore(now)) {
        throw ValidationException('Waktu mulai tidak boleh di masa lalu');
      }

      if (end.isBefore(start)) {
        throw ValidationException(
          'Waktu selesai tidak boleh lebih awal dari waktu mulai',
        );
      }
    }
  }
}
