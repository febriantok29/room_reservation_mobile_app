import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';

class RoomService {
  static final _cachedRooms = <Room>[];

  static RoomService? _instance;

  RoomService._();

  static RoomService getInstance() {
    _instance ??= RoomService._();
    return _instance!;
  }

  Future<List<Room>> getRoomList({
    bool showDeleted = false,
    bool showMaintenance = true,
    String? searchKeyword,
    bool forceRefresh = false,
  }) async {
    // Fetch dari Firestore jika:
    // 1. Cache kosong, ATAU
    // 2. forceRefresh = true, ATAU
    // 3. ensureFullCache = true tapi cache belum lengkap
    if (_cachedRooms.isEmpty || forceRefresh) {
      final client = await FirestoreClient.create(Room.collectionName);

      final response = await client.getAll();

      final docs = response.docs;

      // Clear cache jika force refresh
      if (forceRefresh && _cachedRooms.isNotEmpty) {
        _cachedRooms.clear();
      }

      for (final doc in docs) {
        if (!doc.exists) continue;

        final data = doc.data();

        final room = Room.fromFirestore(data, doc.id);

        // Cek apakah room sudah ada di cache (by ID)
        final existingIndex = _cachedRooms.indexWhere((r) => r.id == room.id);

        if (existingIndex >= 0) {
          // Update room yang sudah ada
          _cachedRooms[existingIndex] = room;
        } else {
          // Tambah room baru
          _cachedRooms.add(room);
        }
      }
    }

    final result = <Room>[];
    final keyword = searchKeyword?.trim().toLowerCase();

    for (final room in _cachedRooms) {
      if (!showDeleted && room.isDeleted) {
        continue;
      }

      if (!showMaintenance && room.isMaintenance == true) {
        continue;
      }

      if (keyword != null && keyword.isNotEmpty) {
        final name = room.name?.toLowerCase() ?? '';
        final location = room.location?.toLowerCase() ?? '';
        final description = room.description?.toLowerCase() ?? '';

        if (!name.contains(keyword) &&
            !location.contains(keyword) &&
            !description.contains(keyword)) {
          continue;
        }
      }

      result.add(room);
    }

    return result;
  }

  Future<List<Room>> getByIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return [];
    }

    final cachedRooms = _cachedRooms
        .where((room) => ids.contains(room.id))
        .toList();

    if (cachedRooms.length == ids.length) {
      return cachedRooms;
    }

    final unCachedIds = ids
        .difference(cachedRooms.map((e) => e.id).toSet())
        .toList();

    if (unCachedIds.isEmpty) {
      return cachedRooms;
    }

    final client = await FirestoreClient.create(Room.collectionName);
    final snapshot = await client.query(
      field: FieldPath.documentId,
      whereIn: unCachedIds,
    );

    final fetchedRooms = <Room>[];

    for (final doc in snapshot.docs) {
      if (!doc.exists) continue;

      final data = doc.data();
      final room = Room.fromFirestore(data, doc.id);

      fetchedRooms.add(room);
      _updateCache(room);
    }

    return [...cachedRooms, ...fetchedRooms];
  }

  Future<Room?> getRoomByDoc(
    DocumentReference roomRef, {
    bool forceRefresh = false,
  }) async {
    final roomId = roomRef.id;

    if (roomId.isEmpty) {
      return null;
    }

    if (!forceRefresh) {
      final cachedRoom = _cachedRooms.where((room) => room.id == roomId);

      if (cachedRoom.isNotEmpty) {
        return cachedRoom.first;
      }
    }

    try {
      final client = await FirestoreClient.create(Room.collectionName);
      final doc = await client.get(roomId);

      if (doc.exists) {
        final data = doc.data() ?? {};
        final room = Room.fromFirestore(data, doc.id);

        _updateCache(room);

        return room;
      }
    } catch (e) {
      debugPrint('Error fetching room from Firestore: $e');

      return null;
    }

    return null;
  }

  Future<List<Room>> getAvailableRoom({
    required DateTime start,
    required DateTime end,
    String? searchKeyword,
    bool forceRefresh = false,
  }) async {
    try {
      if (start.isAfter(end)) {
        throw 'Waktu mulai tidak boleh lebih besar dari waktu selesai';
      }

      await getRoomList(showMaintenance: false, forceRefresh: forceRefresh);

      final reservationService = ReservationService.getInstance();

      // Ambil reservasi yang OVERLAP dengan waktu yang dicari
      final overlappingReservations = await reservationService
          .getReservationList(
            startDate: start,
            endDate: end,
            checkOverlap: true,
          );

      // Dapatkan ID ruangan yang sudah direservasi (overlap dengan waktu yang dicari)
      final reservedRoomIds = overlappingReservations
          .where((reservation) => reservation.roomRef != null)
          .map((reservation) => reservation.roomRef!.id)
          .toSet();

      // Ambil dari cache (yang sudah lengkap berkat getRoomList di atas)
      final allRooms = _cachedRooms
          .where((room) => !room.isDeleted && room.isMaintenance != true)
          .toList();

      // Filter: ambil ruangan yang TIDAK ada di reservedRoomIds
      List<Room> availableRooms = allRooms.where((room) {
        // Skip jika ruangan ada dalam daftar yang sudah direservasi
        if (reservedRoomIds.contains(room.id)) return false;

        return true;
      }).toList();

      // Filter dengan searchKeyword jika ada
      if (searchKeyword != null && searchKeyword.trim().isNotEmpty) {
        final keyword = searchKeyword.trim().toLowerCase();

        availableRooms = availableRooms.where((room) {
          final name = room.name?.toLowerCase() ?? '';
          final location = room.location?.toLowerCase() ?? '';
          final description = room.description?.toLowerCase() ?? '';

          return name.contains(keyword) ||
              location.contains(keyword) ||
              description.contains(keyword);
        }).toList();
      }

      return availableRooms;
    } catch (_) {
      rethrow;
    }
  }

  Future<Room> createRoom(Room room) async {
    final client = await FirestoreClient.create(Room.collectionName);

    room.prepareForCreate();
    final payload = room.toFirestore();

    final doc = await client.add(payload);

    final createdRoom = Room.fromFirestore(payload, doc.id);

    _updateCache(createdRoom);

    return createdRoom;
  }

  Future<Room> updateRoom(Room room) async {
    if (room.id == null) {
      throw 'Silakan pilih ruangan yang akan diperbarui terlebih dahulu';
    }

    final client = await FirestoreClient.create(Room.collectionName);

    room.prepareForUpdate();
    final payload = room.toFirestore();

    await client.update(room.id!, payload);

    _updateCache(room);

    return room;
  }

  Future<void> deleteRoom(Room room) async {
    if (room.id == null) {
      throw 'Silakan pilih ruangan yang akan dihapus terlebih dahulu';
    }

    final client = await FirestoreClient.create(Room.collectionName);

    room.markAsDeleted();
    final payload = room.toFirestore();

    await client.update(room.id!, payload);

    _updateCache(room);
  }

  Future<void> permanentDeleteRoom(String roomId) async {
    if (roomId.isEmpty) {
      throw 'ID ruangan tidak boleh kosong';
    }

    final client = await FirestoreClient.create(Room.collectionName);

    await client.delete(roomId);

    _removeFromCache(roomId);
  }

  Future<List<Room>> refreshCache() {
    return getRoomList(forceRefresh: true);
  }

  void _removeFromCache(String roomId) {
    _cachedRooms.removeWhere((room) => room.id == roomId);
    // Tidak reset _isFullyCached karena hanya remove 1 item
  }

  void _updateCache(Room room) {
    if (room.id == null) return;

    final index = _cachedRooms.indexWhere((r) => r.id == room.id);

    if (index >= 0) {
      _cachedRooms[index] = room;
    } else {
      _cachedRooms.add(room);
    }
  }

  /// Mendapatkan jumlah ruangan yang tersedia (tidak maintenance, tidak deleted)
  Future<int> getAvailableRoomCount({bool forceRefresh = false}) async {
    final rooms = await getRoomList(
      showDeleted: false,
      showMaintenance: false,
      forceRefresh: forceRefresh,
    );

    return rooms.where((room) => room.isMaintenance != true).length;
  }
}
