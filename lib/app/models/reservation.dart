import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:intl/intl.dart';

class Reservation {
  String? id;
  String? userId;
  String? roomId;
  String? startTime;
  String? endTime;
  num? visitorCount;
  String? approvalNote;
  String? purpose;
  String? status;
  String? approvedBy;
  DateTime? approvedAt;
  String? createdBy;
  String? updatedBy;
  String? deletedBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  Room? room;
  User? user;

  Reservation({
    this.id,
    this.userId,
    this.roomId,
    this.startTime,
    this.endTime,
    this.visitorCount,
    this.approvalNote,
    this.purpose,
    this.status,
    this.approvedBy,
    this.approvedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.room,
    this.user,
  });

  Reservation.fromJson(dynamic json) {
    id = json['id'];
    userId = json['userId'];
    roomId = json['roomId'];
    startTime = json['startTime'];
    endTime = json['endTime'];
    visitorCount = json['visitorCount'];
    approvalNote = json['approvalNote'];
    purpose = json['purpose'];
    status = json['status'];
    approvedBy = json['approvedBy'];
    approvedAt = DateTime.tryParse('${json['approvedAt']}')?.toLocal();
    createdBy = json['createdBy'];
    updatedBy = json['updatedBy'];
    deletedBy = json['deletedBy'];
    createdAt = DateTime.tryParse('${json['createdAt']}')?.toLocal();
    updatedAt = DateTime.tryParse('${json['updatedAt']}')?.toLocal();
    deletedAt = DateTime.tryParse('${json['deletedAt']}')?.toLocal();
    room = json['room'] != null ? Room.fromJson(json['room']) : null;
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  String get formattedRange {
    if (startTime == null || endTime == null) return '';

    final start = DateTime.parse(startTime!);
    final end = DateTime.parse(endTime!);

    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('HH:mm');

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      // Same day
      return '${dateFormatter.format(start)} ${timeFormatter.format(start)} - ${timeFormatter.format(end)}';
    } else {
      // Different days
      return '${dateFormatter.format(start)} ${timeFormatter.format(start)} - ${dateFormatter.format(end)} ${timeFormatter.format(end)}';
    }
  }
}

class User {
  String? id;
  String? username;
  String? email;

  User({this.id, this.username, this.email});

  User.fromJson(dynamic json) {
    id = json['id'];
    username = json['username'];
    email = json['email'];
  }
}
