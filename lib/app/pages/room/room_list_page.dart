import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/pages/base_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/room/room_detail_page.dart';
import 'package:rapa_track_mobile_app/app/repositories/room_list_repository.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/cards/room_grid_card.dart';
import 'package:rapa_track_mobile_app/app/ui_items/cards/room_row_card.dart';
import 'package:rapa_track_mobile_app/app/widgets/filter_bottom_sheet.dart';

class RoomListPage extends StatefulWidget {
  final Profile user;

  const RoomListPage({super.key, required this.user});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  late RoomListRepository _repository;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  int _listKey = 0;

  int? _selectedFloor;
  int _minCapacity = 1;

  int get _activeFilterCount =>
      (_selectedFloor != null ? 1 : 0) + (_minCapacity > 1 ? 1 : 0);

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

  Future<void> _showFilterSheet(
    void Function(Map<String, dynamic>?) onApplyFilter,
  ) async {
    int? tempFloor = _selectedFloor;
    final capacityController = TextEditingController(
      text: _minCapacity > 1 ? '$_minCapacity' : '',
    );

    await FilterBottomSheet.show(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => FilterBottomSheet(
          title: 'Filter Ruangan',
          onReset: () => setSheetState(() {
            tempFloor = null;
            capacityController.clear();
          }),
          onApply: () {
            final parsed = int.tryParse(capacityController.text.trim());
            setState(() {
              _selectedFloor = tempFloor;
              _minCapacity = (parsed == null || parsed < 1) ? 1 : parsed;
            });
            _applyFilters(onApplyFilter);
            Navigator.of(sheetContext).pop();
          },
          children: [
            FilterSection(
              label: 'Lantai',
              child: Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [null, 1, 2, 3, 4]
                    .map(
                      (floor) => FilterPill(
                        label: floor == null ? 'Semua' : 'Lantai $floor',
                        isSelected: tempFloor == floor,
                        onTap: () => setSheetState(() => tempFloor = floor),
                      ),
                    )
                    .toList(),
              ),
            ),
            FilterSection(
              label: 'Kapasitas Minimal',
              child: TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: AppSizes.fontSm),
                decoration: InputDecoration(
                  hintText: 'Semua kapasitas',
                  hintStyle: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textDisabled,
                  ),
                  suffixText: 'orang',
                  suffixStyle: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    capacityController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseListPage<Room>(
      key: ValueKey(_listKey),
      pageTitle: 'Daftar Ruangan Meeting',
      repository: _repository,
      itemBuilder: _buildRoomCard,
      gridItemBuilder: _buildRoomGridCard,
      emptyIcon: Icons.meeting_room_outlined,
      emptyTitle: 'Tidak Ada Ruangan',
      emptySubtitle: 'Belum ada ruangan yang tersedia',
      floatingActionButton: widget.user.isAdmin
          ? FloatingActionButton(
              onPressed: _navigateToAddRoom,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
      customFilterBuilder: _buildFilterSection,
      onFilterPressed: _showFilterSheet,
      activeFilterCount: _activeFilterCount,
      onFetchData: _repository.fetchList,
    );
  }

  Future<void> _navigateToAddRoom() async {
    final needsRefresh = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomDetailPage(user: widget.user)),
    );
    if (needsRefresh == true) _forceRefreshList();
  }

  Future<void> _navigateToEditRoom(Room room) async {
    final needsRefresh = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(user: widget.user, room: room),
      ),
    );
    if (needsRefresh == true) _forceRefreshList();
  }

  void _forceRefreshList() {
    _repository.reset();
    setState(() => _listKey++);
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
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(
          AppSizes.md,
          AppSizes.md,
          AppSizes.md,
          AppSizes.sm,
        ),
        child: _buildSearchField(onApplyFilter),
      ),
    );
  }

  Widget _buildSearchField(void Function(Map<String, dynamic>?) onApplyFilter) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari ruangan...',
        hintStyle: const TextStyle(
          fontSize: AppSizes.fontSm,
          color: AppColors.grey,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: AppSizes.iconSm,
          color: AppColors.grey,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: AppSizes.iconSm),
                onPressed: () {
                  _searchController.clear();
                  _applyFilters(onApplyFilter);
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
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
      ),
      onChanged: (v) {
        setState(() {});
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 600), () {
          _applyFilters(onApplyFilter);
        });
      },
    );
  }

  Widget _buildRoomCard(Room room) {
    return RoomRowCard(
      room: room,
      onTap: () => _navigateToViewRoom(room),
      onEdit: widget.user.isAdmin ? () => _navigateToEditRoom(room) : null,
    );
  }

  Widget _buildRoomGridCard(Room room) {
    return RoomGridCard(
      room: room,
      onTap: () => _navigateToViewRoom(room),
      onEdit: widget.user.isAdmin ? () => _navigateToEditRoom(room) : null,
    );
  }
}
