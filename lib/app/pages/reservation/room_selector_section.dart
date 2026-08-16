import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/services/facility_service.dart';
import 'package:rapa_track_mobile_app/app/services/room_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/cards/room_row_card.dart';
import 'package:rapa_track_mobile_app/app/ui_items/room_facility_filter.dart';

class RoomSelectorSection extends StatefulWidget {
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? selectedRoomId;

  /// Callback saat ruangan dipilih. Jika di-set, widget dipakai inline
  /// (tidak pop Navigator) — cocok untuk wizard.
  final void Function(Room room)? onRoomSelected;

  /// Jika true, widget mengisi tinggi penuh (dipakai inline di wizard).
  final bool expand;

  const RoomSelectorSection({
    super.key,
    this.startDateTime,
    this.endDateTime,
    this.selectedRoomId,
    this.onRoomSelected,
    this.expand = false,
  });

  @override
  State<RoomSelectorSection> createState() => _RoomSelectorSectionState();

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
            expand: true,
          ),
        ),
      ),
    );
  }
}

class _RoomSelectorSectionState extends State<RoomSelectorSection> {
  final _roomApiService = RoomService();
  final _facilityApiService = FacilityService();
  final _searchController = TextEditingController();

  String _searchKeyword = '';
  List<String> _selectedFacilityIds = [];
  List<RoomFacility> _availableFacilities = [];
  Future<List<Room>>? _roomsFuture;
  Timer? _debounceTimer;

  bool get _isTimeBasedQuery =>
      widget.startDateTime != null && widget.endDateTime != null;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _loadRooms();
    _loadFacilitiesFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

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

  Future<List<Room>> _loadRooms({bool forceRefresh = false}) async {
    try {
      final rooms = await _roomApiService.getRoomList(
        search: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        availableOnly: _isTimeBasedQuery
            ? true
            : null, // If not time based, don't filter available
        startTime: widget.startDateTime,
        endTime: widget.endDateTime,
        facilityIds: _selectedFacilityIds.isNotEmpty
            ? _selectedFacilityIds
            : null,
        perPage: 100,
      );

      // Manual filtering for facilities if backend doesn't support facilityIds fully
      return _filterByFacilities(rooms);
    } catch (e) {
      throw 'Gagal memuat ruangan: ${e.toString()}';
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      setState(() {
        _searchKeyword = value;
        _roomsFuture = _loadRooms();
      });
    });
  }

  void _onFacilityFilterChanged(List<String> selectedIds) {
    setState(() {
      _selectedFacilityIds = selectedIds;
      _roomsFuture = _loadRooms();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _roomsFuture = _loadRooms(forceRefresh: true);
    });

    await _loadFacilitiesFromApi(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _buildSearchField(),
        if (_availableFacilities.isNotEmpty) ...[
          const SizedBox(height: AppSizes.sm),
          RoomFacilityFilter(
            availableFacilities: _availableFacilities,
            selectedFacilityIds: _selectedFacilityIds,
            onChanged: _onFacilityFilterChanged,
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        Expanded(child: _buildContent()),
      ],
    );

    if (widget.expand) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          0,
          AppSizes.lg,
          AppSizes.lg,
        ),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.sm,
        AppSizes.lg,
        AppSizes.md,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: content,
    );
  }

  Widget _buildContent() {
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
              iconColor: AppColors.error,
              message: snapshot.error.toString(),
              messageColor: AppColors.error,
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return _buildRefreshableState(
              icon: Icons.meeting_room_outlined,
              iconColor: AppColors.textDisabled,
              message: _searchKeyword.isNotEmpty
                  ? 'Tidak ada ruangan dengan kata kunci "$_searchKeyword"'
                  : 'Tidak ada ruangan tersedia',
              messageColor: AppColors.textSecondary,
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

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari ruangan...',
          hintStyle: const TextStyle(
            fontSize: AppSizes.fontSm,
            color: AppColors.textDisabled,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: AppSizes.iconSm,
            color: AppColors.grey,
          ),
          suffixIcon: _searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: AppSizes.iconSm),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

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
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: AppSizes.iconXl, color: iconColor),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: messageColor),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'Tarik ke bawah untuk refresh',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: AppSizes.fontXs,
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

  Widget _buildRoomList(List<Room> rooms) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      itemCount: rooms.length,
      itemBuilder: (_, index) {
        final room = rooms[index];
        final isSelected = room.id == widget.selectedRoomId;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: RoomRowCard(
            room: room,
            isSelected: isSelected,
            showChevron: false,
            onTap: () {
              if (widget.onRoomSelected != null) {
                widget.onRoomSelected!(room);
              } else {
                Navigator.of(context).pop(room);
              }
            },
          ),
        );
      },
    );
  }
}
