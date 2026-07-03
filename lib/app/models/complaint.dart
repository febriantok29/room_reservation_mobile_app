import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/base_model.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';

enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  rejected;

  String get displayName {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Menunggu';
      case ComplaintStatus.inProgress:
        return 'Diproses';
      case ComplaintStatus.resolved:
        return 'Selesai';
      case ComplaintStatus.rejected:
        return 'Ditolak';
    }
  }

  /// Icon untuk status
  IconData get icon {
    switch (this) {
      case ComplaintStatus.pending:
        return Icons.pending;
      case ComplaintStatus.inProgress:
        return Icons.sync;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }

  /// Warna untuk status
  Color get color {
    switch (this) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
    }
  }

  static ComplaintStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ComplaintStatus.pending;
      case 'in_progress':
      case 'inprogress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'rejected':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.pending;
    }
  }
}

class Complaint extends BaseModel {
  final String? userId;
  final String? roomId;
  final String? message;
  final ComplaintStatus status;
  final String? adminResponse;
  final DateTime? respondedAt;

  // Relations
  Room? room;
  Profile? user;

  Complaint({
    super.id,
    this.userId,
    this.roomId,
    this.message,
    this.status = ComplaintStatus.pending,
    this.adminResponse,
    this.respondedAt,
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    this.room,
    this.user,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    final rawStatus = '${json['status'] ?? 'pending'}'.toLowerCase();

    Room? room;
    if (json['room'] is Map<String, dynamic>) {
      room = Room.fromJson(json['room']);
    }

    Profile? user;
    if (json['user'] is Map<String, dynamic>) {
      user = Profile.fromJson(json['user'] as Map<String, dynamic>);
    }

    final complaint = Complaint(
      userId: json['user_id']?.toString(),
      roomId: json['room_id']?.toString(),
      message: json['message']?.toString(),
      status: ComplaintStatus.fromString(rawStatus),
      adminResponse: json['admin_response']?.toString(),
      respondedAt: DateTime.tryParse(
        '${json['responded_at'] ?? ''}',
      )?.toLocal(),
      room: room,
      user: user,
    );

    complaint.setCommonFieldsFromJson(json);

    return complaint;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'room_id': roomId,
      'message': message,
      'status': status.name,
      'admin_response': adminResponse,
      'responded_at': respondedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Complaint copyWith({
    String? id,
    String? userId,
    String? roomId,
    String? message,
    ComplaintStatus? status,
    String? adminResponse,
    DateTime? respondedAt,
    Room? room,
    Profile? user,
  }) {
    return Complaint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      message: message ?? this.message,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      room: room ?? this.room,
      user: user ?? this.user,
    );
  }
}
