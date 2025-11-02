import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/pages/room/room_list_modal_bottom_sheet.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

class RoomListPage extends StatefulWidget {
  final Profile user;

  const RoomListPage({super.key, required this.user});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  final _roomService = RoomService.getInstance();
  late Future<List<Room>> _rooms;

  // State untuk filter
  bool _showAll = false;
  String _searchKeyword = '';
  final _searchController = TextEditingController();

  // Debounce timer untuk pencarian
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadRooms({bool forceRefresh = false}) {
    setState(() {
      _rooms = _roomService.getRoomList(
        showAll: _showAll,
        searchKeyword: _searchKeyword,
        forceRefresh: forceRefresh,
      );
    });
  }

  // Fungsi pencarian dengan debounce
  void _searchRooms(String keyword) {
    // Batalkan timer sebelumnya jika masih berjalan
    _debounceTimer?.cancel();

    // Atur timer baru (2 detik)
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_searchKeyword != keyword) {
        setState(() {
          _searchKeyword = keyword;
          _loadRooms();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _loadRooms(forceRefresh: true);
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Daftar Ruangan Meeting')),
          floatingActionButton: _addRoomButton(),
          body: Column(children: [_buildFilterSection(), _buildContent()]),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final filter = <Widget>[
      // Kolom pencarian
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari ruangan...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchRooms('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: _searchRooms,
        ),
      ),
    ];

    // Filter untuk admin
    if (widget.user.isAdmin) {
      filter.add(
        Row(
          children: [
            const Expanded(child: Text('Lihat semua ruangan')),
            Switch(
              value: _showAll,
              onChanged: (_) {
                setState(() {
                  _showAll = !_showAll;
                  _loadRooms();
                });
              },
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      color: Colors.grey[200],
      child: Column(children: filter),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<Room>>(
      future: _rooms,
      builder: (_, snapshot) {
        // Tampilkan indikator loading selama pencarian
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.only(top: 24.0),

              child: Text('Gagal memuat ruangan: ${snapshot.error}'),
            ),
          );
        }

        final data = snapshot.data ?? [];

        // Tampilkan pesan kosong yang berbeda berdasarkan pencarian
        if (data.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: Center(
              child: _searchKeyword.isNotEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada ruangan dengan kata kunci "$_searchKeyword"',
                        ),
                      ],
                    )
                  : const Text('Tidak ada ruangan tersedia.'),
            ),
          );
        }

        return Flexible(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, index) {
              final room = data[index];

              Widget card = _buildCard(room);

              if (widget.user.isAdmin) {
                card = Slidable(
                  key: ValueKey(room.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _showRoomBottomSheet(room),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Edit',
                      ),
                      SlidableAction(
                        onPressed: (_) => _confirmDeleteRoom(room),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Hapus',
                      ),
                    ],
                  ),
                  child: card,
                );
              }

              final isLast = index == data.length - 1;
              if (isLast) {
                card = Padding(
                  padding: const EdgeInsets.only(bottom: 96.0),
                  child: card,
                );
              }

              return card;
            },
          ),
        );
      },
    );
  }

  /// Widget untuk menampilkan detail ruangan dalam bentuk kartu
  Widget _buildCard(Room room) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon ruangan di sebelah kiri
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.meeting_room,
                size: 32,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 16),

            // Informasi ruangan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama ruangan
                  Text(
                    room.name ?? '(Tanpa Nama)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Lokasi
                  _buildRoomInfoRow(
                    icon: Icons.location_on,
                    value: room.location ?? '-',
                  ),
                  const SizedBox(height: 4),

                  // Kapasitas
                  _buildRoomInfoRow(
                    icon: Icons.people,
                    value: 'Kapasitas: ${room.capacity ?? '-'} orang',
                  ),

                  // Status maintenance
                  if (room.isMaintenance == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildStatusTag(
                        Icons.build,
                        'DALAM PERAWATAN',
                        Colors.orange.shade800,
                      ),
                    ),

                  // Status hapus untuk admin
                  if (room.deletedAt != null && widget.user.isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildStatusTag(
                        Icons.delete,
                        'Dihapus pada ${room.deletedAtFormatted}',
                        Colors.red.shade800,
                      ),
                    ),
                ],
              ),
            ),

            // Tombol Book di sebelah kanan
            ElevatedButton(
              onPressed: () {
                // TODO: Implementasi navigasi ke halaman booking
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Book',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk menampilkan baris informasi ruangan dengan ikon
  Widget _buildRoomInfoRow({required IconData icon, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// Widget untuk menampilkan status khusus (maintenance, deleted)
  Widget _buildStatusTag(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _addRoomButton() {
    if (!widget.user.isAdmin) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () => _showRoomBottomSheet(),
      tooltip: 'Tambah Ruangan',
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  /// Menampilkan bottom sheet untuk tambah/edit ruangan
  /// Menggunakan widget RoomListModalBottomSheet yang sudah direfaktor
  void _showRoomBottomSheet([Room? room]) async {
    // Menggunakan factory method static untuk menampilkan bottom sheet
    final bool? needRefresh = await RoomListModalBottomSheet.show(
      context: context,
      user: widget.user,
      room: room,
      onSuccess: null,
    );

    // Refresh daftar ruangan jika berhasil menambahkan/mengubah ruangan
    if (needRefresh == true) {
      setState(() {
        _loadRooms(); // Reload room data
      });
    }
  }

  /// Menampilkan konfirmasi sebelum menghapus ruangan
  void _confirmDeleteRoom(Room room) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ruangan "${room.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Hapus ruangan (soft delete)
        await _roomService.deleteRoom(room);

        // Reload daftar ruangan
        setState(() {
          _loadRooms();
        });

        if (!mounted) {
          return;
        }

        // Tampilkan snackbar

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ruangan ${room.name} berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus ruangan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
