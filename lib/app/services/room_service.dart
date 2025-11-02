import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/firestore/base_firestore_model.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';

class RoomService {
  static final _cachedRooms = <Room>[];
  // Flag untuk track apakah cache sudah lengkap
  static bool _isFullyCached = false;

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
    // Parameter baru untuk memastikan cache lengkap
    bool ensureFullCache = false,
  }) async {
    // Fetch dari Firestore jika:
    // 1. Cache kosong, ATAU
    // 2. forceRefresh = true, ATAU
    // 3. ensureFullCache = true tapi cache belum lengkap
    if (_cachedRooms.isEmpty ||
        forceRefresh ||
        (ensureFullCache && !_isFullyCached)) {
      final client = await FirestoreClient.create(Room.collectionName);
      Query<Map<String, dynamic>> query = client.getCollectionRef();

      if (!showDeleted) {
        query = query.where(BaseFirestoreModel.deletedAtField, isEqualTo: null);
      }

      if (!showMaintenance) {
        query = query.where('isMaintenance', isEqualTo: false);
      }

      final response = await query.get();

      final docs = response.docs;

      // Clear cache jika force refresh
      if (forceRefresh && _cachedRooms.isNotEmpty) {
        _cachedRooms.clear();
        _isFullyCached = false;
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

      // Tandai cache sebagai lengkap setelah fetch dari Firestore
      _isFullyCached = true;

      debugPrint(
        'Room cache loaded: ${_cachedRooms.length} rooms (fully cached: $_isFullyCached)',
      );
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

    final unCachedIds = ids.difference(cachedRooms.map((e) => e.id).toSet());

    if (unCachedIds.isEmpty) {
      return cachedRooms;
    }

    final client = await FirestoreClient.create(Room.collectionName);
    final snapshot = await client
        .query(field: FieldPath.documentId, whereIn: unCachedIds.toList())
        .get();

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
  }) async {
    try {
      if (start.isAfter(end)) {
        throw 'Waktu mulai tidak boleh lebih besar dari waktu selesai';
      }

      // PENTING: Pastikan cache terisi LENGKAP dengan semua ruangan dari Firestore
      // ensureFullCache = true akan memaksa fetch jika cache belum lengkap
      // Ini memastikan SEMUA ruangan dari master data (m_room) tersedia,
      // bukan hanya ruangan yang sudah pernah ada di reservasi
      await getRoomList(
        showMaintenance: false,
        ensureFullCache: true, // Parameter kunci untuk memastikan cache lengkap
      );

      debugPrint('Available rooms check - Cache size: ${_cachedRooms.length}');

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

      debugPrint('Reserved room IDs: $reservedRoomIds');

      // Ambil dari cache (yang sudah lengkap berkat getRoomList di atas)
      final allRooms = _cachedRooms
          .where((room) => !room.isDeleted && room.isMaintenance != true)
          .toList();

      debugPrint('All non-maintenance rooms: ${allRooms.length}');

      // Filter: ambil ruangan yang TIDAK ada di reservedRoomIds
      final availableRooms = allRooms.where((room) {
        // Skip jika ruangan ada dalam daftar yang sudah direservasi
        if (reservedRoomIds.contains(room.id)) return false;

        return true;
      }).toList();

      debugPrint('Available rooms after filter: ${availableRooms.length}');

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
      throw ValidationException('ID ruangan tidak boleh kosong');
    }

    final client = await FirestoreClient.create(Room.collectionName);

    await client.delete(roomId);

    _removeFromCache(roomId);
  }

  Future<List<Room>> refreshCache() async {
    _isFullyCached = false; // Reset flag
    return getRoomList(forceRefresh: true, ensureFullCache: true);
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
      debugPrint('Room cache updated for ID: ${room.id}');
    } else {
      _cachedRooms.add(room);
      debugPrint('Room added to cache with ID: ${room.id}');
    }
  }
}
