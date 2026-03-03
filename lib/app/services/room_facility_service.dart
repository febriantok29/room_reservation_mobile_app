import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/models/room_facility.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

/// Service untuk mengelola fasilitas ruangan
/// Fasilitas diambil dari data room yang sudah ada (facilityIds)
/// dan dikembalikan sebagai distinct list untuk autocomplete/filter
class RoomFacilityService {
  static RoomFacilityService? _instance;

  RoomFacilityService._();

  static RoomFacilityService getInstance() {
    _instance ??= RoomFacilityService._();
    return _instance!;
  }

  /// Mendapatkan semua fasilitas unik dari semua room yang ada
  /// Digunakan untuk autocomplete dan filter
  Future<List<RoomFacility>> getAllFacilities({
    bool forceRefresh = false,
  }) async {
    try {
      final roomService = RoomService.getInstance();

      // Ambil semua room (termasuk yang maintenance, tapi exclude yang deleted)
      final rooms = await roomService.getRoomList(
        showDeleted: false,
        showMaintenance: true,
        forceRefresh: forceRefresh,
      );

      // Kumpulkan semua facility IDs yang unik
      final Set<String> allFacilityIds = {};

      for (final room in rooms) {
        if (room.facilityIds != null && room.facilityIds!.isNotEmpty) {
          allFacilityIds.addAll(room.facilityIds!);
        }
      }

      // Convert ke RoomFacility objects
      final facilities = allFacilityIds
          .map((id) => RoomFacility.fromString(id))
          .toList();

      // Sort alphabetically
      facilities.sort((a, b) => a.name.compareTo(b.name));

      return facilities;
    } catch (e) {
      throw 'Gagal memuat daftar fasilitas: ${e.toString()}';
    }
  }

  /// Mendapatkan fasilitas dari room tertentu
  List<RoomFacility> getFacilitiesFromRoom(Room room) {
    if (room.facilityIds == null || room.facilityIds!.isEmpty) {
      return [];
    }

    return room.facilityIds!.map((id) => RoomFacility.fromString(id)).toList();
  }

  /// Filter rooms berdasarkan fasilitas yang dipilih
  /// Menggunakan AND logic: room harus memiliki SEMUA fasilitas yang dipilih
  List<Room> filterRoomsByFacilities(
    List<Room> rooms,
    List<String> selectedFacilityIds,
  ) {
    if (selectedFacilityIds.isEmpty) {
      return rooms;
    }

    return rooms.where((room) {
      if (room.facilityIds == null || room.facilityIds!.isEmpty) {
        return false;
      }

      // Check apakah room punya SEMUA fasilitas yang dipilih (AND logic)
      return selectedFacilityIds.every(
        (selectedId) => room.facilityIds!.contains(selectedId),
      );
    }).toList();
  }

  /// Validasi dan normalize facility IDs
  /// Memastikan facility ID dalam format lowercase dan trim
  List<String> normalizeFacilityIds(List<String> facilityIds) {
    return facilityIds
        .map((id) => id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();
  }

  /// Merge facility IDs baru dengan yang sudah ada
  /// Digunakan saat admin menambahkan fasilitas baru via manual input
  List<String> mergeFacilityIds(List<String> existingIds, List<String> newIds) {
    final normalized = normalizeFacilityIds([...existingIds, ...newIds]);
    normalized.sort();
    return normalized;
  }
}
