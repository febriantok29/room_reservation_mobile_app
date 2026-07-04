import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/base_model.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';

enum ComplaintStatus {
  open,
  inProgress,
  resolved,
  rejected;

  String get displayName {
    switch (this) {
      case ComplaintStatus.open:
        return 'Menunggu';
      case ComplaintStatus.inProgress:
        return 'Diproses';
      case ComplaintStatus.resolved:
        return 'Selesai';
      case ComplaintStatus.rejected:
        return 'Ditolak';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintStatus.open:
        return Icons.pending;
      case ComplaintStatus.inProgress:
        return Icons.sync;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.open:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
    }
  }

  bool get isClosed =>
      this == ComplaintStatus.resolved || this == ComplaintStatus.rejected;

  static ComplaintStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return ComplaintStatus.open;
      case 'in_progress':
      case 'inprogress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'rejected':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.open;
    }
  }
}

class Complaint extends BaseModel {
  final String? reportedBy;
  final String? roomId;
  final String? reservationId;
  final String? facilityId;
  final String? title;
  final String? description;
  final String? photoPath;
  final ComplaintStatus status;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  Room? room;
  Reservation? reservation;
  RoomFacility? facility;
  Profile? reporter;
  Profile? resolver;

  Complaint({
    super.id,
    this.reportedBy,
    this.roomId,
    this.reservationId,
    this.facilityId,
    this.title,
    this.description,
    this.photoPath,
    this.status = ComplaintStatus.open,
    this.resolutionNotes,
    this.resolvedAt,
    this.resolvedBy,
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    this.room,
    this.reservation,
    this.facility,
    this.reporter,
    this.resolver,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    final rawStatus = '${json['status'] ?? 'open'}'.toLowerCase();

    Room? room;
    if (json['room'] is Map<String, dynamic>) {
      room = Room.fromJson(json['room']);
    }

    Reservation? reservation;
    if (json['reservation'] is Map<String, dynamic>) {
      reservation = Reservation.fromJson(json['reservation']);
    }

    RoomFacility? facility;
    if (json['facility'] is Map<String, dynamic>) {
      facility = RoomFacility.fromJson(json['facility']);
    }

    Profile? reporter;
    if (json['reporter'] is Map<String, dynamic>) {
      reporter = Profile.fromJson(json['reporter']);
    }

    Profile? resolver;
    if (json['resolver'] is Map<String, dynamic>) {
      resolver = Profile.fromJson(json['resolver']);
    }

    final complaint = Complaint(
      reportedBy: json['reported_by']?.toString(),
      roomId: json['room_id']?.toString(),
      reservationId: json['reservation_id']?.toString(),
      facilityId: json['facility_id']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      photoPath: json['photo_path']?.toString(),
      status: ComplaintStatus.fromString(rawStatus),
      resolutionNotes: json['resolution_notes']?.toString(),
      resolvedAt: DateTime.tryParse('${json['resolved_at'] ?? ''}')?.toLocal(),
      resolvedBy: json['resolved_by']?.toString(),
      room: room,
      reservation: reservation,
      facility: facility,
      reporter: reporter,
      resolver: resolver,
    );

    complaint.setCommonFieldsFromJson(json);

    return complaint;
  }
}
