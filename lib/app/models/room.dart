import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  String? id;
  String? name;
  num? capacity;
  String? location;
  String? description;
  bool? isMaintenance;
  String? createdBy;
  String? updatedBy;
  String? deletedBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  Room({
    this.id,
    this.name,
    this.capacity,
    this.location,
    this.description,
    this.isMaintenance,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Room.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    capacity = json['capacity'];
    location = json['location'];
    description = json['description'];
    isMaintenance = json['isMaintenance'];
    createdBy = json['createdBy'];
    updatedBy = json['updatedBy'];
    deletedBy = json['deletedBy'];
    createdAt = DateTime.tryParse('${json['createdAt']}')?.toLocal();
    updatedAt = DateTime.tryParse('${json['updatedAt']}')?.toLocal();
    deletedAt = DateTime.tryParse('${json['deletedAt']}')?.toLocal();
  }

  String get imageUrl {
    final roomId = id?.hashCode ?? name?.hashCode ?? 0;
    final random = Random(roomId);
    final backgroundColor = (random.nextInt(0xFFFFFF) + 0x1000000)
        .toRadixString(16)
        .substring(1)
        .toUpperCase();
    final textColor = 'FFFFFF';

    return 'https://placehold.co/600x400/$backgroundColor/$textColor/png?text=${Uri.encodeComponent(name ?? 'Room')}&font=roboto';
  }

  /// Create a Room instance from a Firestore document
  factory Room.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Room(
      id: documentId,
      name: data['name'],
      capacity: data['capacity'],
      location: data['location'],
      description: data['description'],
      isMaintenance: data['isMaintenance'] ?? false,
      createdBy: data['createdBy'],
      updatedBy: data['updatedBy'],
      deletedBy: data['deletedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{};

    if (name != null) map['name'] = name;
    if (capacity != null) map['capacity'] = capacity;
    if (location != null) map['location'] = location;
    if (description != null) map['description'] = description;
    map['isMaintenance'] = isMaintenance ?? false;
    if (createdBy != null) map['createdBy'] = createdBy;
    if (updatedBy != null) map['updatedBy'] = updatedBy;
    if (deletedBy != null) map['deletedBy'] = deletedBy;
    if (createdAt != null) map['createdAt'] = Timestamp.fromDate(createdAt!);
    if (updatedAt != null) map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    if (deletedAt != null) map['deletedAt'] = Timestamp.fromDate(deletedAt!);

    return map;
  }
}
