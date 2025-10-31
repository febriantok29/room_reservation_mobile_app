import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';

/// Service untuk mengelola operasi terkait ruangan
class RoomService {
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
    if (_cachedRooms.length <= 1 || forceRefresh) {
      final client = await FirestoreClient.create(Room.collectionName);
      QuerySnapshot<Map<String, dynamic>> response;

      if (showAll) {
        response = await client.getAll();
      } else {
        response = await client
            .query(field: 'isDeleted', isEqualTo: null)
            .get();
      }

      final docs = response.docs;

      // Kosongkan cache jika refresh dipaksa
      if (forceRefresh && _cachedRooms.isNotEmpty) {
        _cachedRooms.clear();
      }

      // Isi cache dengan data baru
      for (final doc in docs) {
        if (!doc.exists) continue;

        final data = doc.data();

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

      // Tambahkan ke hasil dan update cache
      fetchedRooms.add(room);
      _updateCache(room);
    }

    // Gabungkan hasil dari cache dan Firestore
    return [...cachedRooms, ...fetchedRooms];
  }

  /// Mendapatkan ruangan berdasarkan ID
  /// [roomRef] - ID ruangan yang dicari
  /// [forceRefresh] - Jika true, memaksa refresh data dari backend meskipun cache ada
  Future<Room?> getRoomByDoc(
    DocumentReference roomRef, {
    bool forceRefresh = false,
  }) async {
    final roomId = roomRef.id;

    if (roomId.isEmpty) {
      return null;
    }

    // Cek cache terlebih dahulu jika tidak dipaksa refresh
    if (!forceRefresh) {
      final cachedRoom = _cachedRooms.where((room) => room.id == roomId);

      if (cachedRoom.isNotEmpty) {
        return cachedRoom.first;
      }
    }

    // Coba dapatkan dari Firestore dulu
    try {
      final client = await FirestoreClient.create(Room.collectionName);
      final doc = await client.get(roomId);

      if (doc.exists) {
        final data = doc.data() ?? {};
        final room = Room.fromFirestore(data, doc.id);

        // Update cache
        _updateCache(room);

        return room;
      }
    } catch (e) {
      debugPrint('Error fetching room from Firestore: $e');

      return null;
    }

    return null;
  }

  /// Mendapatkan ruangan yang tersedia pada rentang waktu tertentu
  Future<List<Room>> getAvailableRoom({
    required DateTime start,
    required DateTime end,
  }) async {
    // Validasi format waktu
    try {
      if (start.isAfter(end)) {
        throw 'Waktu mulai tidak boleh lebih besar dari waktu selesai';
      }

      final reservationService = ReservationService.getInstance();

      final reservedRooms = await reservationService.getReservationList(
        startDate: start,
        endDate: end,
      );

      final reservedRoomIds = reservedRooms
          .where((reservation) => reservation.roomRef != null)
          .map((reservation) => reservation.roomRef!.id)
          .toSet();

      final allRooms = await getRoomList(showAll: false);

      final result = allRooms
          .where((room) => !reservedRoomIds.contains(room.id))
          .toList();

      // Remove duplicated, but keep one instance in cache
      final uniqueResult = <String, Room>{};
      for (final room in result) {
        uniqueResult[room.id!] = room;
      }

      return uniqueResult.values.toList();
    } catch (_) {
      rethrow;
    }
  }

  // Create room
  Future<Room> createRoom(Room room) async {
    final client = await FirestoreClient.create(Room.collectionName);

    room.prepareForCreate();
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
      throw 'Silakan pilih ruangan yang akan diperbarui terlebih dahulu';
    }

    final client = await FirestoreClient.create(Room.collectionName);

    room.prepareForUpdate();
    final payload = room.toFirestore();

    await client.update(room.id!, payload);

    // Update cache
    _updateCache(room);

    return room;
  }

  /// Menghapus ruangan (soft delete)
  Future<void> deleteRoom(Room room) async {
    if (room.id == null) {
      throw 'Silakan pilih ruangan yang akan dihapus terlebih dahulu';
    }

    final client = await FirestoreClient.create(Room.collectionName);

    // Soft delete dengan marking deletedAt dan deletedBy
    room.markAsDeleted();
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

    final client = await FirestoreClient.create(Room.collectionName);

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
    if (room.id == null) return; // Skip jika tidak ada ID

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
