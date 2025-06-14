import 'dart:math';

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
}
