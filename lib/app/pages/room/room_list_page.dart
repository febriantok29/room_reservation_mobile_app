import 'dart:async';

import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/pages/room/room_detail_page.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

class RoomListPage extends StatefulWidget {
  final Profile user;

  const RoomListPage({super.key, required this.user});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _roomService = RoomService();

  String _searchKeyword = '';
  final _searchController = TextEditingController();

  Future<List<Room>>? _roomsFuture;

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

  void _loadRooms() {
    setState(() {
      _roomsFuture = _roomService.getRoomList(search: _searchKeyword);
    });
  }

  void _searchRooms(String keyword) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_searchKeyword != keyword) {
        _searchKeyword = keyword;
        _loadRooms();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Daftar Ruangan Meeting')),
        body: Column(children: [
          _buildFilterSection(),
          Expanded(child: _buildContent()),
        ]),
        floatingActionButton: widget.user.isAdmin
            ? FloatingActionButton(
                onPressed: _navigateToAddRoom,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Future<void> _navigateToAddRoom() async {
    final needsRefresh = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomDetailPage(user: widget.user)),
    );

    if (needsRefresh) {
      _loadRooms();
    }
  }

  Future<void> _navigateToEditRoom(Room room) async {
    final needsRefresh = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(user: widget.user, room: room),
      ),
    );

    if (needsRefresh) {
      _loadRooms();
    }
  }

  void _navigateToViewRoom(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailPage.view(user: widget.user, room: room),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      color: Colors.grey[200],
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () async {
        _loadRooms();
        await _roomsFuture;
      },
      child: FutureBuilder<List<Room>>(
        future: _roomsFuture,
        builder: (_, snapshot) {
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
                padding: const EdgeInsets.only(top: 24.0),
                child: Text('Gagal memuat ruangan: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0),
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
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
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
          );
        },
      ),
    );
  }

  Widget _buildCard(Room room) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name ?? '(Tanpa Nama)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  _buildRoomInfoRow(
                    icon: Icons.location_on,
                    value: room.location,
                  ),
                  const SizedBox(height: 4),

                  _buildRoomInfoRow(
                    icon: Icons.people,
                    value: 'Kapasitas: ${room.capacity ?? '-'} orang',
                  ),

                  if (room.isMaintenance == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildStatusTag(
                        Icons.build,
                        'DALAM PERAWATAN',
                        Colors.orange.shade800,
                      ),
                    ),

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

            Column(
              children: [
                ElevatedButton(
                  onPressed: () => _navigateToViewRoom(room),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Detail',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.user.isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToEditRoom(room),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildStatusTag(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: color.withAlpha(128)),
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
