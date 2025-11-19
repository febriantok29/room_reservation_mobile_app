import 'package:flutter/material.dart';

/// Model untuk fasilitas ruangan
/// Fasilitas disimpan sebagai simple data structure (name + optional icon)
/// dan digunakan untuk filtering dan display
class RoomFacility {
  final String id;
  final String name;
  final IconData? icon;

  const RoomFacility({required this.id, required this.name, this.icon});

  factory RoomFacility.fromString(String name) {
    return RoomFacility(
      id: name.toLowerCase().trim(),
      name: name.trim(),
      icon: _getIconForFacility(name.toLowerCase().trim()),
    );
  }

  factory RoomFacility.fromJson(Map<String, dynamic> json) {
    return RoomFacility(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: _getIconForFacility(json['id'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  /// Mendapatkan icon berdasarkan nama fasilitas
  /// Icon ini bersifat default dan dapat dikustomisasi
  static IconData? _getIconForFacility(String facilityId) {
    final Map<String, IconData> iconMap = {
      'ac': Icons.ac_unit,
      'air conditioner': Icons.ac_unit,
      'projector': Icons.video_label,
      'proyektor': Icons.video_label,
      'whiteboard': Icons.dashboard,
      'papan tulis': Icons.dashboard,
      'wifi': Icons.wifi,
      'internet': Icons.wifi,
      'tv': Icons.tv,
      'television': Icons.tv,
      'speaker': Icons.volume_up,
      'sound system': Icons.volume_up,
      'microphone': Icons.mic,
      'mic': Icons.mic,
      'computer': Icons.computer,
      'komputer': Icons.computer,
      'printer': Icons.print,
      'dispenser': Icons.local_drink,
      'water dispenser': Icons.local_drink,
      'telephone': Icons.phone,
      'telepon': Icons.phone,
      'screen': Icons.screenshot_monitor,
      'layar': Icons.screenshot_monitor,
      'desk': Icons.desk,
      'meja': Icons.desk,
      'chair': Icons.chair,
      'kursi': Icons.chair,
      'sofa': Icons.weekend,
      'table': Icons.table_restaurant,
      'parking': Icons.local_parking,
      'parkir': Icons.local_parking,
    };

    // Cari exact match
    if (iconMap.containsKey(facilityId)) {
      return iconMap[facilityId];
    }

    // Cari partial match
    for (var entry in iconMap.entries) {
      if (facilityId.contains(entry.key) || entry.key.contains(facilityId)) {
        return entry.value;
      }
    }

    // Default icon
    return Icons.check_circle_outline;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomFacility &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;

  RoomFacility copyWith({String? id, String? name, IconData? icon}) {
    return RoomFacility(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }
}
