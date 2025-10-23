import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:room_reservation_mobile_app/app/core/firestore/firestore_client.dart';
import 'package:room_reservation_mobile_app/app/core/network/api_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/api_response.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';

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
    if (_cachedRooms.isEmpty || forceRefresh) {
      final client = await FirestoreClient.create(Room.collectionName);
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

    // Cek cache dulu untuk ruangan yang sudah ada
    final cachedRooms = <Room>[];
    final uncachedIds = <DocumentReference>[];

    // Cari di cache terlebih dahulu
    for (final id in ids) {
      final cachedRoom = _cachedRooms.where((room) => room.id == id);

      if (cachedRoom.isNotEmpty) {
        cachedRooms.add(cachedRoom.first);
      } else {
        uncachedIds.add(
          FirebaseFirestore.instance.doc('$Room.collectionName/$id'),
        );
      }
    }

    // Jika semua ID sudah ada di cache, kembalikan langsung
    if (uncachedIds.isEmpty) {
      return cachedRooms;
    }

    // Ambil dari Firestore hanya untuk ID yang tidak ada di cache
    final client = await FirestoreClient.create(Room.collectionName);
    final snapshot = await client.query(field: 'roomId', whereIn: uncachedIds);

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
    if (roomRef.id.isEmpty) {
      return null;
    }

    // Cek cache terlebih dahulu jika tidak dipaksa refresh
    if (!forceRefresh) {
      final cachedRoom = _cachedRooms.where((room) => room.id == roomRef.id);
      if (cachedRoom.isNotEmpty) {
        return cachedRoom.first;
      }
    }

    // Coba dapatkan dari Firestore dulu
    try {
      final client = await FirestoreClient.create(Room.collectionName);
      final doc = await client.get(roomRef.id);

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
  @Deprecated('Removed this after firebase firestore migration')
  Future<ApiResponse<List<Room>>> getRawAvailableRoom({
    required DateTime start,
    required DateTime end,
    int page = 1,
    int? limit,
  }) async {
    // Validasi format waktu
    try {
      if (start.isAfter(end)) {
        throw 'Waktu mulai tidak boleh lebih besar dari waktu selesai';
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
        throw 'Waktu mulai tidak boleh di masa lalu';
      }

      // final client = await FirestoreClient.create(Room.collectionName);
      //
      // final response = await client.advancedQuery(
      //   conditions: [
      //     QueryCondition(field: 'isDeleted', isEqualTo: null),
      //     QueryCondition(field: 'isMaintenance', isEqualTo: false),
      //   ],
      // );
      //
      // final result = <Room>[];
      //
      // final docs = response.docs;
      //
      // for (final doc in docs) {
      //   if (!doc.exists) continue;
      //
      //   final data = doc.data();
      //
      //   final room = Room.fromFirestore(data, doc.id);
      //   result.add(room);
      // }
      //
      // return result;

      final builder = await ApiClient.create('Room.getAvailable');
      builder
          .addQuery('startDate', start.toIso8601String())
          .addQuery('endDate', end.toIso8601String());

      if (limit != null) {
        builder.addQuery('limit', '$limit');
      }

      builder.addQuery('page', '$page');

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
  @Deprecated('Removed this after firebase firestore migration')
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
