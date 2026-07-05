import 'dart:math';

import 'package:rapa_track_mobile_app/app/models/base_model.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';

class Room extends BaseModel {
  final String? name;
  final int? floor;
  final num? capacity;
  final String? description;
  final bool? isMaintenance;
  final List<RoomFacility>? facilities;

  Room({
    super.id,
    this.name,
    this.floor,
    this.capacity,
    this.description,
    this.isMaintenance,
    this.facilities,
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

    List<RoomFacility>? facilities;
    final rawFacilities = json['facilities'];
    if (rawFacilities is List) {
      facilities = rawFacilities
          .whereType<Map<String, dynamic>>()
          .map((f) => RoomFacility.fromJson(f))
          .toList();
    }

    final isMaintenanceValue = json['is_maintenance'] == true;

    final room = Room(
      name: json['name']?.toString(),
      floor: int.tryParse('${json['floor'] ?? ''}'),
      capacity: json['capacity'],
      description: json['description']?.toString(),
      isMaintenance: isMaintenanceValue,
      facilities: facilities,
    );

    room.setCommonFieldsFromJson(json);

    return room;
  }

  /// Lokasi berdasarkan lantai
  String get location {
    if (floor == null) return '-';
    return 'Lantai $floor';
  }

  String get imageUrl {
    final roomId = id?.hashCode ?? name?.hashCode ?? 0;
    final random = Random(roomId);
    final backgroundColor = (random.nextInt(0xFFFFFF) + 0x1000000)
        .toRadixString(16)
        .substring(1)
        .toUpperCase();
    const textColor = 'FFFFFF';

    return 'https://placehold.co/600x400/$backgroundColor/$textColor/png?text=${Uri.encodeComponent(name ?? 'Room')}&font=roboto';
  }

  Room copyWith({
    String? id,
    String? name,
    int? floor,
    num? capacity,
    String? description,
    bool? isMaintenance,
    List<RoomFacility>? facilities,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      isMaintenance: isMaintenance ?? this.isMaintenance,
      facilities: facilities ?? this.facilities,
      createdBy: createdBy,
      updatedBy: updatedBy,
      deletedBy: deletedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}
