import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/models/room_facility.dart';
import 'package:room_reservation_mobile_app/app/providers/room_providers.dart';
import 'package:room_reservation_mobile_app/app/services/facility_api_service.dart';
import 'package:room_reservation_mobile_app/app/services/room_api_service.dart';
import 'package:room_reservation_mobile_app/app/ui_items/room_facility_filter.dart';
import 'package:room_reservation_mobile_app/app/ui_items/room_facility_chips.dart';

class RoomSelectorSection extends ConsumerStatefulWidget {
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? selectedRoomId;

  const RoomSelectorSection({
    super.key,
    this.startDateTime,
    this.endDateTime,
    this.selectedRoomId,
  });

  @override
  ConsumerState<RoomSelectorSection> createState() =>
      _RoomSelectorSectionState();

  /// Menampilkan bottom sheet untuk memilih ruangan
  static Future<Room?> showBottomSheet({
    required BuildContext context,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? selectedRoomId,
  }) {
    return showModalBottomSheet<Room>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RoomSelectorSection(
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        selectedRoomId: selectedRoomId,
      ),
    );
  }

  static Future<Room?> showPage({
    required BuildContext context,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? selectedRoomId,
  }) {
    return Navigator.of(context).push<Room>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Pilih Ruangan')),
          body: RoomSelectorSection(
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            selectedRoomId: selectedRoomId,
          ),
        ),
      ),
    );
  }
}

class _RoomSelectorSectionState extends ConsumerState<RoomSelectorSection> {
  final _roomApiService = RoomApiService();
  final _facilityApiService = FacilityApiService();
  final _searchController = TextEditingController();

  String _searchKeyword = '';
  List<String> _selectedFacilityIds = [];
  List<RoomFacility> _availableFacilities = [];
  Future<List<Room>>? _roomsFuture;
  int _refreshNonce = 0;
  Timer? _debounceTimer;

  bool get _isTimeBasedQuery =>
      widget.startDateTime != null && widget.endDateTime != null;

  @override
  void initState() {
    super.initState();
    if (_isTimeBasedQuery) {
      _roomsFuture = _loadRooms();
    }
    _loadFacilitiesFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load daftar fasilitas yang tersedia dari API
  Future<void> _loadFacilitiesFromApi({bool forceRefresh = false}) async {
    try {
      final facilities = await _facilityApiService.getFacilityList(
        perPage: 100,
      );

      if (mounted) {
        setState(() {
          _availableFacilities = facilities;
        });
      }
    } catch (e) {
      debugPrint('Failed to load facilities: $e');
    }
  }

  /// Load daftar ruangan yang tersedia
  Future<List<Room>> _loadRooms({bool forceRefresh = false}) async {
    try {
      final rooms = await _roomApiService.getRoomList(
        search: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        availableOnly: true,
        startTime: widget.startDateTime,
        endTime: widget.endDateTime,
        facilityIds: _selectedFacilityIds.isNotEmpty
            ? _selectedFacilityIds
            : null,
        perPage: 100,
      );

      return rooms;
    } catch (e) {
      throw 'Gagal memuat ruangan: ${e.toString()}';
    }
  }

  /// Reload rooms dengan keyword baru (dengan debounce)
  void _onSearchChanged(String value) {
    // Cancel timer sebelumnya jika ada
    _debounceTimer?.cancel();

    // Buat timer baru dengan delay 1 detik
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _searchKeyword = value;
        if (_isTimeBasedQuery) {
          _roomsFuture = _loadRooms();
        }
      });
    });
  }

  /// Handle perubahan facility filter
  void _onFacilityFilterChanged(List<String> selectedIds) {
    setState(() {
      _selectedFacilityIds = selectedIds;
      if (_isTimeBasedQuery) {
        _roomsFuture = _loadRooms();
      }
    });
  }

  /// Handle pull to refresh
  Future<void> _onRefresh() async {
    setState(() {
      if (_isTimeBasedQuery) {
        _roomsFuture = _loadRooms(forceRefresh: true);
      } else {
        _refreshNonce++;
      }
    });

    if (!_isTimeBasedQuery) {
      ref.invalidate(
        roomListByQueryProvider(
          RoomListQuery(
            showMaintenance: false,
            searchKeyword: _searchKeyword,
            forceRefresh: true,
          ),
        ),
      );
    }

    await _loadFacilitiesFromApi(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(),
          if (_availableFacilities.isNotEmpty) ...[
            const SizedBox(height: 8),
            RoomFacilityFilter(
              availableFacilities: _availableFacilities,
              selectedFacilityIds: _selectedFacilityIds,
              onChanged: _onFacilityFilterChanged,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_isTimeBasedQuery) {
      final query = RoomListQuery(
        showMaintenance: false,
        searchKeyword: _searchKeyword,
        forceRefresh: _refreshNonce > 0,
      );

      final roomState = ref.watch(roomListByQueryProvider(query));

      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: roomState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildRefreshableState(
            icon: Icons.error_outline,
            iconColor: Colors.red.shade300,
            message: error.toString(),
            messageColor: Colors.red.shade700,
          ),
          data: (rooms) {
            if (_refreshNonce > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _refreshNonce = 0;
                  });
                }
              });
            }

            final filteredRooms = _filterByFacilities(rooms);

            if (filteredRooms.isEmpty) {
              return _buildRefreshableState(
                icon: Icons.meeting_room_outlined,
                iconColor: Colors.grey.shade400,
                message: _searchKeyword.isNotEmpty
                    ? 'Tidak ada ruangan dengan kata kunci "$_searchKeyword"'
                    : 'Tidak ada ruangan tersedia',
                messageColor: Colors.grey.shade600,
              );
            }

            return _buildRoomList(filteredRooms);
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: FutureBuilder<List<Room>>(
        future: _roomsFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildRefreshableState(
              icon: Icons.error_outline,
              iconColor: Colors.red.shade300,
              message: snapshot.error.toString(),
              messageColor: Colors.red.shade700,
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return _buildRefreshableState(
              icon: Icons.meeting_room_outlined,
              iconColor: Colors.grey.shade400,
              message: _searchKeyword.isNotEmpty
                  ? 'Tidak ada ruangan dengan kata kunci "$_searchKeyword"'
                  : 'Tidak ada ruangan tersedia',
              messageColor: Colors.grey.shade600,
            );
          }

          return _buildRoomList(rooms);
        },
      ),
    );
  }

  List<Room> _filterByFacilities(List<Room> rooms) {
    if (_selectedFacilityIds.isEmpty) {
      return rooms;
    }

    return rooms.where((room) {
      final roomFacilities = room.facilities;

      if (roomFacilities == null || roomFacilities.isEmpty) {
        return false;
      }

      final roomFacilityNames = roomFacilities
          .map((f) => f.name.toLowerCase())
          .toSet();
      return _selectedFacilityIds.every(
        (id) => roomFacilityNames.contains(id.toLowerCase()),
      );
    }).toList();
  }

  /// Widget search field
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari ruangan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  /// Generic widget untuk state yang bisa di-refresh (error/empty)
  Widget _buildRefreshableState({
    required IconData icon,
    required Color iconColor,
    required String message,
    required Color messageColor,
  }) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: iconColor),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: messageColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tarik ke bawah untuk refresh',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Widget daftar ruangan
  Widget _buildRoomList(List<Room> rooms) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: rooms.length,
      itemBuilder: (_, index) {
        final room = rooms[index];
        final isSelected = room.id == widget.selectedRoomId;
        final facilities = room.facilities ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          color: isSelected ? Colors.blue.shade50 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(room);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room.name ?? 'Ruangan',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    room.location,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (room.capacity != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      'Kapasitas: ${room.capacity} orang',
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ],
                  if (facilities.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    RoomFacilityChips(facilities: facilities),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
