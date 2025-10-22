import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/core/network/api_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/api_response.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';

/// Service untuk mengelola operasi terkait ruangan
class RoomService {
  static const _roomCollection = 'm_rooms';

  static final _cachedRooms = <Room>[];

  static RoomService? _instance;

  RoomService._();

  /// Singleton instance
  static RoomService getInstance() {
    _instance ??= RoomService._();
    return _instance!;
  }

  /// Mendapatkan semua ruangan
  /// [showAll] - Jika true, menampilkan juga ruangan yang sudah dihapus
  /// [searchKeyword] - Keyword untuk mencari ruangan berdasarkan nama, lokasi, atau deskripsi
  /// [forceRefresh] - Jika true, memaksa refresh data dari Firestore meskipun cache ada
  Future<List<Room>> getRoomList({
    bool showAll = false,
    String? searchKeyword,
    bool forceRefresh = false,
  }) async {
    // Jika cache kosong atau dipaksa refresh, ambil data dari Firestore
    if (_cachedRooms.isEmpty || forceRefresh) {
      final client = await FirestoreClient.create(_roomCollection);
      final response = await client.getAll();
      final docs = response.docs;

      // Kosongkan cache jika refresh dipaksa
      if (forceRefresh && _cachedRooms.isNotEmpty) {
        _cachedRooms.clear();
      }

      // Isi cache dengan data baru
      for (final doc in docs) {
        if (!doc.exists) continue;

        final data = doc.data();
        if (data == null || data is! Map<String, dynamic>) continue;

        final room = Room.fromFirestore(data, doc.id);
        _cachedRooms.add(room);
      }
    }

    // Filter ruangan berdasarkan parameter
    final result = <Room>[];
    final keyword = searchKeyword?.trim().toLowerCase();

    for (final room in _cachedRooms) {
      // Filter ruangan yang sudah dihapus jika showAll = false
      if (!showAll && room.isDeleted) {
        continue;
      }

      // Filter berdasarkan keyword jika ada
      if (keyword != null && keyword.isNotEmpty) {
        final name = room.name?.toLowerCase() ?? '';
        final location = room.location?.toLowerCase() ?? '';
        final description = room.description?.toLowerCase() ?? '';

        // Jika tidak ada yang cocok dengan keyword, lewati
        if (!name.contains(keyword) &&
            !location.contains(keyword) &&
            !description.contains(keyword)) {
          continue;
        }
      }

      // Tambahkan ke hasil jika lolos filter
      result.add(room);
    }

    return result;
  }

  /// Mendapatkan ruangan berdasarkan ID
  Future<Room> getRoomById(String id) async {
    if (id.isEmpty) {
      throw ValidationException('ID ruangan tidak boleh kosong');
    }

    final builder = await ApiClient.create('Room.getById');
    builder.addParameter('id', id);

    final response = await builder.get<Room>(
      fromJson: Room.fromJson,
      errorMessage: 'Gagal memuat detail ruangan',
    );

    final data = response.data;

    if (data == null) {
      throw NotFoundException('Ruangan dengan ID $id tidak ditemukan');
    }

    return data;
  }

  /// Mendapatkan ruangan yang tersedia pada rentang waktu tertentu
  Future<ApiResponse<List<Room>>> getRawAvailableRoom({
    required DateTime start,
    required DateTime end,
    int page = 1,
    int? limit,
  }) async {
    // Validasi format waktu
    try {
      if (start.isAfter(end)) {
        throw ValidationException(
          'Waktu mulai tidak boleh lebih besar dari waktu selesai',
        );
      }

      // Compare dates up to minutes for more accurate validation
      final now = DateTime.now();
      final currentTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      );
      final startCompare = DateTime(
        start.year,
        start.month,
        start.day,
        start.hour,
        start.minute,
      );

      if (startCompare.isBefore(currentTime)) {
        throw ValidationException('Waktu mulai tidak boleh di masa lalu');
      }

      final builder = await ApiClient.create('Room.getAvailable');
      builder
          .addQuery('startDate', start.toIso8601String())
          .addQuery('endDate', end.toIso8601String());

      if (limit != null) {
        builder.addQuery('limit', '$limit');
      }

      builder.addQuery('page', '$page');

      return builder.get<List<Room>>(
        fromJson: (json) => (json as List)
            .map((item) => Room.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException('Format waktu tidak valid');
    }
  }

  /// Cari ruangan berdasarkan keyword
  Future<List<Room>> searchRooms(String keyword) async {
    if (keyword.trim().isEmpty) {
      return await getRoomList();
    }

    final builder = await ApiClient.create('Room.getAll');
    builder.addQuery('search', keyword.trim());

    final response = await builder.get<List<Room>>(
      fromJson: (json) => (json as List)
          .map((item) => Room.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: 'Gagal mencari ruangan',
    );

    return response.data ?? [];
  }

  // Create room
  Future<Room> createRoom(Room room) async {
    final client = await FirestoreClient.create(_roomCollection);

    final payload = room.toFirestore();

    final doc = await client.add(payload);

    final createdRoom = Room.fromFirestore(payload, doc.id);

    // Update cache
    _updateCache(createdRoom);

    return createdRoom;
  }

  /// Update ruangan yang sudah ada
  Future<Room> updateRoom(Room room) async {
    if (room.id == null) {
      throw ValidationException('ID ruangan tidak boleh kosong');
    }

    final client = await FirestoreClient.create(_roomCollection);

    final payload = room.toFirestore();

    await client.update(room.id!, payload);

    // Update cache
    _updateCache(room);

    return room;
  }

  /// Menghapus ruangan (soft delete)
  Future<void> deleteRoom(Room room, String userId) async {
    if (room.id == null) {
      throw ValidationException('ID ruangan tidak boleh kosong');
    }

    final client = await FirestoreClient.create(_roomCollection);

    // Soft delete dengan marking deletedAt dan deletedBy
    room.markAsDeleted(userId);

    final payload = room.toFirestore();

    await client.update(room.id!, payload);

    // Update cache dengan ruangan yang sudah ditandai dihapus
    _updateCache(room);
  }

  /// Menghapus ruangan secara permanen (hard delete)
  Future<void> permanentDeleteRoom(String roomId) async {
    if (roomId.isEmpty) {
      throw ValidationException('ID ruangan tidak boleh kosong');
    }

    final client = await FirestoreClient.create(_roomCollection);

    await client.delete(roomId);

    // Hapus dari cache jika ada
    _removeFromCache(roomId);
  }

  /// Memaksa refresh cache ruangan
  Future<List<Room>> refreshCache() async {
    return getRoomList(forceRefresh: true);
  }

  /// Menghapus ruangan dari cache berdasarkan ID
  void _removeFromCache(String roomId) {
    _cachedRooms.removeWhere((room) => room.id == roomId);
  }

  /// Menambahkan atau memperbaharui ruangan dalam cache
  void _updateCache(Room room) {
    final index = _cachedRooms.indexWhere((r) => r.id == room.id);

    if (index >= 0) {
      _cachedRooms[index] = room;
    } else {
      _cachedRooms.add(room);
    }
  }
}
