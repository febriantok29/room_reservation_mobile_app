import 'package:intl/intl.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/base_model.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';

class Reservation extends BaseModel {
  final String? userId;
  final String? roomId;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? visitorCount;
  final String? purpose;

  ReservationStatus status;

  Room? room;
  Profile? user;

  Reservation({
    super.id,
    this.userId,
    this.roomId,
    this.startTime,
    this.endTime,
    this.visitorCount,
    this.purpose,
    this.status = ReservationStatus.pending,
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    this.room,
    this.user,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final rawStatus = '${json['status'] ?? ''}'.toLowerCase();

    Room? room;
    if (json['room'] is Map<String, dynamic>) {
      room = Room.fromJson(json['room']);
    }

    Profile? user;
    if (json['user'] is Map<String, dynamic>) {
      user = Profile.fromJson(json['user'] as Map<String, dynamic>);
    }

    final reservation = Reservation(
      userId: json['user_id']?.toString(),
      roomId: json['room_id']?.toString(),
      startTime: DateTime.tryParse('${json['start_time'] ?? ''}')?.toLocal(),
      endTime: DateTime.tryParse('${json['end_time'] ?? ''}')?.toLocal(),
      visitorCount: int.tryParse('${json['visitor_count'] ?? 0}') ?? 0,
      purpose: json['purpose']?.toString(),
      status: ReservationStatusExtension.fromString(rawStatus),
      room: room,
      user: user,
    );

    reservation.setCommonFieldsFromJson(json);

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
      return '${_dateFormatter.format(start)} ${_timeFormatter.format(start)} - ${_timeFormatter.format(end)}';
    } else {
      return '${_dateFormatter.format(start)} ${_timeFormatter.format(start)} - ${_dateFormatter.format(end)} ${_timeFormatter.format(end)}';
    }
  }

  String get statusDisplayName => status.displayName;
  String get statusDescription => status.description;
  String get statusColorHex => status.colorHex;

  bool canBeRescheduledBy(Profile currentUser) {
    final isOwner = userId != null && userId == currentUser.id;
    if (!isOwner && !currentUser.isAdmin) return false;
    if (status != ReservationStatus.pending) return false;
    if (startTime == null) return false;
    return startTime!.isAfter(DateTime.now());
  }

  Reservation copyWith({
    String? id,
    String? userId,
    String? roomId,
    DateTime? startTime,
    DateTime? endTime,
    int? visitorCount,
    String? purpose,
    ReservationStatus? status,
    Room? room,
    Profile? user,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      visitorCount: visitorCount ?? this.visitorCount,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      room: room ?? this.room,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'room_id': roomId,
      'start_time': startTime?.toUtc().toIso8601String(),
      'end_time': endTime?.toUtc().toIso8601String(),
      'purpose': purpose,
      'visitor_count': visitorCount,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final data = <String, dynamic>{};
    if (roomId != null) data['room_id'] = roomId;
    if (startTime != null) {
      data['start_time'] = startTime!.toUtc().toIso8601String();
    }
    if (endTime != null) {
      data['end_time'] = endTime!.toUtc().toIso8601String();
    }
    if (purpose != null) data['purpose'] = purpose;
    if (visitorCount != null) data['visitor_count'] = visitorCount;
    return data;
  }
}
