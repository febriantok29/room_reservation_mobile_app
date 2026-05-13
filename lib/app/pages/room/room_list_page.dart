import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/providers/room_providers.dart';

class RoomListPage extends ConsumerStatefulWidget {
  final Profile user;

  const RoomListPage({super.key, required this.user});

  @override
  ConsumerState<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends ConsumerState<RoomListPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  // State untuk filter
  String _searchKeyword = '';
  final _searchController = TextEditingController();
  int _refreshNonce = 0;

  // Debounce timer untuk pencarian
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadRooms({bool forceRefresh = false}) {
    setState(() {
      if (forceRefresh) {
        _refreshNonce++;
      }
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
          ref.invalidate(
            roomListByQueryProvider(
              RoomListQuery(searchKeyword: _searchKeyword, forceRefresh: true),
            ),
          );
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Daftar Ruangan Meeting')),
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      color: Colors.grey[200],
      child: Column(children: filter),
    );
  }

  Widget _buildContent() {
    final query = RoomListQuery(
      searchKeyword: _searchKeyword,
      forceRefresh: _refreshNonce > 0,
    );

    final roomState = ref.watch(roomListByQueryProvider(query));

    return roomState.when(
      loading: () {
        return const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stack) {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(top: 24.0),

            child: Text('Gagal memuat ruangan: $error'),
          ),
        );
      },
      data: (data) {
        if (_refreshNonce > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _refreshNonce = 0;
              });
            }
          });
        }

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
                    value: room.location,
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
}
