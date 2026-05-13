import 'package:flutter/material.dart';

/// Model untuk fasilitas ruangan dari API
class RoomFacility {
  final String id;
  final String name;
  final String? slug;
  final IconData? icon;

  const RoomFacility({
    required this.id,
    required this.name,
    this.slug,
    this.icon,
  });

  factory RoomFacility.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
    return RoomFacility(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: slug,
      icon: _getIconForSlug(slug),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  /// Mendapatkan icon berdasarkan slug fasilitas
  static IconData? _getIconForSlug(String slug) {
    const Map<String, IconData> iconMap = {
      'ac': Icons.ac_unit,
      'proyektor': Icons.video_label,
      'projector': Icons.video_label,
      'whiteboard': Icons.dashboard,
      'wifi': Icons.wifi,
      'tv': Icons.tv,
      'audio_system': Icons.volume_up,
      'sound_system': Icons.volume_up,
      'microphone': Icons.mic,
      'video_conference': Icons.videocam,
      'computer': Icons.computer,
      'printer': Icons.print,
      'dispenser': Icons.local_drink,
      'coffee_station': Icons.coffee,
      'telephone': Icons.phone,
      'display': Icons.screenshot_monitor,
      'desk': Icons.desk,
      'chair': Icons.chair,
      'sofa': Icons.weekend,
      'parking': Icons.local_parking,
    };

    if (iconMap.containsKey(slug)) {
      return iconMap[slug];
    }

    for (var entry in iconMap.entries) {
      if (slug.contains(entry.key) || entry.key.contains(slug)) {
        return entry.value;
      }
    }

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
