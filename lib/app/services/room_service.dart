import 'package:room_reservation_mobile_app/app/core/network/api_client.dart';
import 'package:room_reservation_mobile_app/app/exceptions/exceptions.dart';
import 'package:room_reservation_mobile_app/app/models/api_response.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';

/// Service untuk mengelola operasi terkait ruangan
class RoomService {
  static RoomService? _instance;

  RoomService._();

  /// Singleton instance
  static RoomService getInstance() {
    _instance ??= RoomService._();
    return _instance!;
  }

  /// Mendapatkan semua ruangan
  Future<List<Room>> getAllRoom() async {
    final builder = await ApiClient.create('Room.getAll');
    final response = await builder.get<List<Room>>(
      fromJson: (json) => (json as List)
          .map((item) => Room.fromJson(item as Map<String, dynamic>))
          .toList(),
      errorMessage: 'Gagal memuat data ruangan',
    );

    return response.data ?? [];
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
      return await getAllRoom();
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
}
