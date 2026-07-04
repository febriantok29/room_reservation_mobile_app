import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/pages/base_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/room/room_detail_page.dart';
import 'package:rapa_track_mobile_app/app/repositories/room_list_repository.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';

class RoomListPage extends StatefulWidget {
  final Profile user;

  const RoomListPage({super.key, required this.user});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  late final RoomListRepository _repository;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Filter states
  int? _selectedFloor;
  int _minCapacity = 1;

  @override
  void initState() {
    super.initState();
    _repository = RoomListRepository();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  void _onSearchChanged(String keyword) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      // Filter will be applied via callback
    });
  }

  Map<String, dynamic> _buildFilters() {
    return {
      if (_searchController.text.isNotEmpty) 'search': _searchController.text,
      if (_selectedFloor != null) 'floor': _selectedFloor,
      if (_minCapacity > 1) 'min_capacity': _minCapacity,
    };
  }

  void _applyFilters(void Function(Map<String, dynamic>?) callback) {
    final filters = _buildFilters();
    callback(filters.isEmpty ? null : filters);
  }

  @override
  Widget build(BuildContext context) {
    return BaseListPage<Room>(
      pageTitle: 'Daftar Ruangan Meeting',
      repository: _repository,
      itemBuilder: _buildRoomCard,
      emptyIcon: Icons.meeting_room_outlined,
      emptyTitle: 'Tidak Ada Ruangan',
      emptySubtitle: 'Belum ada ruangan yang tersedia',
      floatingActionButton: widget.user.isAdmin
          ? FloatingActionButton(
              onPressed: _navigateToAddRoom,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
      customFilterBuilder: _buildFilterSection,
      onFetchData: _repository.fetchList,
    );
  }

  Future<void> _navigateToAddRoom() async {
    final needsRefresh = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomDetailPage(user: widget.user)),
    );

    if (needsRefresh == true) {
      _repository.reset();
      setState(() {});
    }
  }

  Future<void> _navigateToEditRoom(Room room) async {
    final needsRefresh = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(user: widget.user, room: room),
      ),
    );

    if (needsRefresh == true) {
      _repository.reset();
      setState(() {});
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

  Widget _buildFilterSection(
    void Function(Map<String, dynamic>?) onApplyFilter,
  ) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        color: Colors.grey[200],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari ruangan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters(onApplyFilter);
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
                onChanged: (value) {
                  _onSearchChanged(value);
                  _applyFilters(onApplyFilter);
                },
              ),
              const SizedBox(height: 12),
              // Floor filter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.layers, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: _selectedFloor,
                        hint: const Text('Pilih Lantai'),
                        underline: const SizedBox.shrink(),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Lantai'),
                          ),
                          ...List.generate(4, (i) {
                            final floor = i + 1;
                            return DropdownMenuItem<int?>(
                              value: floor,
                              child: Text('Lantai $floor'),
                            );
                          }),
                        ],
                        onChanged: (floor) {
                          setState(() => _selectedFloor = floor);
                          _applyFilters(onApplyFilter);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Capacity filter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kapasitas Minimal: $_minCapacity orang',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _minCapacity.toDouble(),
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '$_minCapacity',
                      onChanged: (value) {
                        setState(() => _minCapacity = value.toInt());
                        _applyFilters(onApplyFilter);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Reset button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedFloor = null;
                    _minCapacity = 1;
                  });
                  _applyFilters(onApplyFilter);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return Container(
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
