import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/base_model.dart';

enum NotificationType {
  reservationCreated,
  reservationApproved,
  reservationRejected,
  reservationCancelled,
  reservationReminder,
  complaintResponse,
  general;

  String get displayName {
    switch (this) {
      case NotificationType.reservationCreated:
        return 'Reservasi Baru';
      case NotificationType.reservationApproved:
        return 'Reservasi Disetujui';
      case NotificationType.reservationRejected:
        return 'Reservasi Ditolak';
      case NotificationType.reservationCancelled:
        return 'Reservasi Dibatalkan';
      case NotificationType.reservationReminder:
        return 'Pengingat Reservasi';
      case NotificationType.complaintResponse:
        return 'Tanggapan Keluhan';
      case NotificationType.general:
        return 'Notifikasi';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.reservationCreated:
        return Icons.event_note;
      case NotificationType.reservationApproved:
        return Icons.check_circle;
      case NotificationType.reservationRejected:
        return Icons.cancel;
      case NotificationType.reservationCancelled:
        return Icons.event_busy;
      case NotificationType.reservationReminder:
        return Icons.notifications_active;
      case NotificationType.complaintResponse:
        return Icons.feedback;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.reservationCreated:
        return Colors.blue;
      case NotificationType.reservationApproved:
        return Colors.green;
      case NotificationType.reservationRejected:
        return Colors.red;
      case NotificationType.reservationCancelled:
        return Colors.orange;
      case NotificationType.reservationReminder:
        return Colors.blue;
      case NotificationType.complaintResponse:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  static NotificationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'reservation_created':
      case 'reservation_pending':
        return NotificationType.reservationCreated;
      case 'reservation_approved':
        return NotificationType.reservationApproved;
      case 'reservation_rejected':
        return NotificationType.reservationRejected;
      case 'reservation_cancelled':
        return NotificationType.reservationCancelled;
      case 'reservation_reminder':
        return NotificationType.reservationReminder;
      case 'complaint_response':
        return NotificationType.complaintResponse;
      default:
        return NotificationType.general;
    }
  }
}

class NotificationPayload {
  final NotificationType type;
  final String? reservationId;
  final String? complaintId;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;

  const NotificationPayload({
    required this.type,
    this.reservationId,
    this.complaintId,
    this.title,
    this.body,
    this.data,
  });

  factory NotificationPayload.fromFcmData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    return NotificationPayload(
      type: NotificationType.fromString(data['type']?.toString() ?? ''),
      reservationId: data['reservation_id']?.toString(),
      complaintId: data['complaint_id']?.toString(),
      title: title,
      body: body,
      data: data,
    );
  }

  factory NotificationPayload.fromLocalPayload(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const NotificationPayload(type: NotificationType.general);
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPayload(
        type: NotificationType.fromString('${json['type'] ?? ''}'),
        reservationId: json['reservation_id']?.toString(),
        complaintId: json['complaint_id']?.toString(),
        title: json['title']?.toString(),
        body: json['body']?.toString(),
        data: json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : null,
      );
    } catch (_) {
      return const NotificationPayload(type: NotificationType.general);
    }
  }

  String toLocalPayload() => jsonEncode({
        'type': type.name,
        'reservation_id': reservationId,
        'complaint_id': complaintId,
        'title': title,
        'body': body,
        'data': data,
      });
}

class NotificationModel extends BaseModel {
  final String? userId;
  final String? title;
  final String? body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;

  NotificationModel({
    super.id,
    this.userId,
    this.title,
    this.body,
    this.type = NotificationType.general,
    this.data,
    this.isRead = false,
    this.readAt,
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawType = '${json['type'] ?? 'general'}';

    Map<String, dynamic>? data;
    if (json['data'] is Map) {
      data = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json['data'] is String) {
      // Parse JSON string if needed
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(json['data'] as String) as Map,
        );
      } catch (_) {
        data = null;
      }
    }

    final notification = NotificationModel(
      userId: json['user_id']?.toString(),
      title: json['title']?.toString(),
      body: json['body']?.toString() ?? json['message']?.toString(),
      type: NotificationType.fromString(rawType),
      data: data,
      isRead: json['is_read'] == true || json['read_at'] != null,
      readAt: DateTime.tryParse('${json['read_at'] ?? ''}')?.toLocal(),
    );

    notification.setCommonFieldsFromJson(json);

    return notification;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  NotificationPayload toPayload() => NotificationPayload(
        type: type,
        reservationId: data?['reservation_id']?.toString(),
        complaintId: data?['complaint_id']?.toString(),
        title: title,
        body: body,
        data: data,
      );

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}
