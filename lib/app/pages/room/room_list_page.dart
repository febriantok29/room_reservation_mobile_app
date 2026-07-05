import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/pages/base_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/room/room_detail_page.dart';
import 'package:rapa_track_mobile_app/app/repositories/room_list_repository.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

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

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _selectedFloor != null ||
      _minCapacity > 1;

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

  void _resetFilters(void Function(Map<String, dynamic>?) onApplyFilter) {
    setState(() {
      _searchController.clear();
      _selectedFloor = null;
      _minCapacity = 1;
    });
    onApplyFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    return BaseListPage<Room>(
      key: ValueKey(_listKey),
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
              child: const Icon(Icons.add, color: AppColors.white),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchField(onApplyFilter),
            const SizedBox(height: AppSizes.sm),
            _buildFilterChips(onApplyFilter),
          ],
        ),
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

  Widget _buildFilterChips(void Function(Map<String, dynamic>?) onApplyFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...[null, 1, 2, 3, 4].map((floorVal) {
            final label = floorVal == null ? 'Semua' : 'Lantai $floorVal';
            final isSelected = _selectedFloor == floorVal;
            return Padding(
              padding: const EdgeInsets.only(right: AppSizes.xs),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) {
                  setState(() => _selectedFloor = floorVal);
                  _applyFilters(onApplyFilter);
                },
                selectedColor: AppColors.primary.withAlpha(30),
                backgroundColor: AppColors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                labelStyle: TextStyle(
                  fontSize: AppSizes.fontXs,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          const SizedBox(width: AppSizes.xs),
          ActionChip(
            avatar: Icon(
              Icons.people_outline,
              size: 14,
              color: _minCapacity > 1 ? AppColors.primary : AppColors.grey,
            ),
            label: Text(
              _minCapacity > 1 ? 'Min. $_minCapacity org' : 'Kapasitas',
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                color: _minCapacity > 1
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight:
                    _minCapacity > 1 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onPressed: () => _showCapacityDialog(onApplyFilter),
            backgroundColor: _minCapacity > 1
                ? AppColors.primary.withAlpha(20)
                : AppColors.white,
            side: BorderSide(
              color: _minCapacity > 1 ? AppColors.primary : AppColors.border,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
            visualDensity: VisualDensity.compact,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: AppSizes.xs),
            ActionChip(
              avatar: Icon(
                Icons.close,
                size: 14,
                color: AppColors.error.withAlpha(200),
              ),
              label: const Text(
                'Reset',
                style: TextStyle(fontSize: AppSizes.fontXs),
              ),
              onPressed: () => _resetFilters(onApplyFilter),
              backgroundColor: AppColors.error.withAlpha(15),
              side: BorderSide(color: AppColors.error.withAlpha(80)),
              labelStyle: TextStyle(color: AppColors.error.withAlpha(200)),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showCapacityDialog(
    void Function(Map<String, dynamic>?) onApplyFilter,
  ) async {
    double temp = _minCapacity.toDouble();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: StatefulBuilder(
          builder: (_, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people,
                size: AppSizes.iconXl,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Kapasitas Minimal',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                '${temp.toInt()} orang',
                style: const TextStyle(
                  fontSize: AppSizes.fontXl,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Slider(
                value: temp,
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: AppColors.primary,
                onChanged: (v) => setLocal(() => temp = v),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _minCapacity = temp.toInt());
                        _applyFilters(onApplyFilter);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final isMaintenance = room.isMaintenance == true;
    final statusColor = isMaintenance ? AppColors.warning : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          onTap: () => _navigateToViewRoom(room),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.sm),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
                            ),
                            child: Icon(
                              Icons.meeting_room,
                              size: AppSizes.iconLg,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  room.name ?? '(Tanpa Nama)',
                                  style: const TextStyle(
                                    fontSize: AppSizes.fontMd,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSizes.xxs),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      room.location,
                                      style: const TextStyle(
                                        fontSize: AppSizes.fontXs,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    const Icon(
                                      Icons.people_outline,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${room.capacity ?? '-'} orang',
                                      style: const TextStyle(
                                        fontSize: AppSizes.fontXs,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isMaintenance) ...[
                                  const SizedBox(height: AppSizes.xs),
                                  _buildStatusBadge(
                                    Icons.build_outlined,
                                    'Dalam Perawatan',
                                    AppColors.warning,
                                  ),
                                ],
                                if (room.deletedAt != null &&
                                    widget.user.isAdmin) ...[
                                  const SizedBox(height: AppSizes.xs),
                                  _buildStatusBadge(
                                    Icons.delete_outlined,
                                    'Dihapus ${room.deletedAtFormatted}',
                                    AppColors.error,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.user.isAdmin)
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: AppSizes.iconSm,
                                color: AppColors.primary,
                              ),
                              onPressed: () => _navigateToEditRoom(room),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              tooltip: 'Edit',
                            ),
                          const Icon(
                            Icons.chevron_right,
                            size: AppSizes.iconMd,
                            color: AppColors.textDisabled,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSizes.xxs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
