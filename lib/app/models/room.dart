import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';

class Room extends BaseFirestoreModel {
  static const String collectionName = 'm_rooms';

  final String? name;
  final num? capacity;
  final String? location;
  final String? description;
  final bool? isMaintenance;
  final List<String>? facilityIds;

  @override
  DocumentReference get reference {
    return FirebaseFirestore.instance.collection(collectionName).doc(id);
  }

  Room({
    super.id,
    this.name,
    this.capacity,
    this.location,
    this.description,
    this.isMaintenance,
    this.facilityIds,
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory Room.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      return Room();
    }

    final rawFacilityIds = json['facilityIds'] ?? json['facility_ids'];

    List<String>? facilityIds;

    if (rawFacilityIds is List) {
      facilityIds = rawFacilityIds
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item['id']?.toString();
            }

            return item?.toString();
          })
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();
    }

    final isMaintenanceValue =
        json['isMaintenance'] ?? json['is_maintenance'] ?? false;

    final locationValue =
        json['location'] ?? _mapFloorToLocation(json['floor']);

    return Room(
      id: json['id'],
      name: json['name'],
      capacity: json['capacity'],
      location: locationValue,
      description: json['description'],
      isMaintenance: isMaintenanceValue == true,
      facilityIds: facilityIds,
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      deletedBy: json['deletedBy'],
      createdAt: DateTime.tryParse(
        '${json['createdAt'] ?? json['created_at']}',
      )?.toLocal(),
      updatedAt: DateTime.tryParse(
        '${json['updatedAt'] ?? json['updated_at']}',
      )?.toLocal(),
      deletedAt: DateTime.tryParse(
        '${json['deletedAt'] ?? json['deleted_at']}',
      )?.toLocal(),
    );
  }

  static String? _mapFloorToLocation(dynamic floorValue) {
    if (floorValue == null) {
      return null;
    }

    final floor = num.tryParse('$floorValue');

    if (floor == null) {
      return null;
    }

    return 'Lantai ${floor.toInt()}';
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

  factory Room.fromFirestore(Map<String, dynamic> data, String documentId) {
    final room = Room(
      id: documentId,
      name: data['name'],
      capacity: data['capacity'],
      location: data['location'],
      description: data['description'],
      isMaintenance: data['isMaintenance'] ?? false,
      facilityIds: data['facilityIds'] != null
          ? List<String>.from(data['facilityIds'])
          : null,
    );

    room.setCommonFields(data, documentId);

    return room;
  }

  Map<String, dynamic> toFirestore() {
    final bool maintenanceValue = isMaintenance == true;

    final map = <String, dynamic>{
      'name': name,
      'capacity': capacity,
      'location': location,
      'description': description,
      'isMaintenance': maintenanceValue,
      'facilityIds': facilityIds ?? [],
    };

    map.addAll(super.toMap());

    return map;
  }

  //   Copy method
  Room copyWith({
    String? id,
    String? name,
    num? capacity,
    String? location,
    String? description,
    bool? isMaintenance,
    List<String>? facilityIds,
    DocumentReference? createdBy,
    DocumentReference? updatedBy,
    DocumentReference? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
      description: description ?? this.description,
      isMaintenance: isMaintenance ?? this.isMaintenance,
      facilityIds: facilityIds ?? this.facilityIds,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
