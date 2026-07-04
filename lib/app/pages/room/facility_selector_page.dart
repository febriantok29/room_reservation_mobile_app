import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/services/facility_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class FacilitySelectorPage extends StatefulWidget {
  final List<RoomFacility> initialSelectedFacilities;

  const FacilitySelectorPage({
    super.key,
    required this.initialSelectedFacilities,
  });

  @override
  State<FacilitySelectorPage> createState() => _FacilitySelectorPageState();
}

class _FacilitySelectorPageState extends State<FacilitySelectorPage> {
  final _service = FacilityService();
  final _searchController = TextEditingController();

  late final _selectedFacilities = List<RoomFacility>.from(
    widget.initialSelectedFacilities,
  );
  late Future<List<RoomFacility>> _facilitiesFuture = _service
      .getFacilityList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _facilitiesFuture = _service.getFacilityList(search: val);
    });
  }

  void _toggleFacility(RoomFacility facility) {
    setState(() {
      final isSelected = _selectedFacilities.any((f) => f.id == facility.id);
      if (isSelected) {
        _selectedFacilities.removeWhere((f) => f.id == facility.id);
      } else {
        _selectedFacilities.add(facility);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectedFacilities.isEmpty
              ? 'Pilih Fasilitas'
              : 'Pilih Fasilitas (${_selectedFacilities.length})',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedFacilities),
            child: const Text(
              'Selesai',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontSm,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildSelectedSummary(),
          Expanded(
            child: Container(color: AppColors.white, child: _buildContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari fasilitas...',
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
                    _onSearchChanged('');
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
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSelectedSummary() {
    return Container(
      width: double.infinity,
      color: AppColors.primary.withAlpha(15),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedFacilities.isEmpty
                ? 'Silakan pilih fasilitas tersedia'
                : '${_selectedFacilities.length} fasilitas dipilih',
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          _selectedFacilities.isEmpty
              ? const SizedBox(height: AppSizes.xl)
              : Wrap(
                  runSpacing: AppSizes.xs,
                  spacing: AppSizes.xs,
                  children: _selectedFacilities.map((facility) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSizes.xs),
                      child: InputChip(
                        label: Text(
                          facility.name,
                          style: const TextStyle(
                            fontSize: AppSizes.fontXs,
                            color: AppColors.primary,
                          ),
                        ),
                        avatar: facility.icon != null
                            ? Icon(
                                facility.icon,
                                size: 14,
                                color: AppColors.primary,
                              )
                            : null,
                        deleteIcon: const Icon(Icons.close, size: 14),
                        deleteIconColor: AppColors.primary,
                        onDeleted: () => _toggleFacility(facility),
                        backgroundColor: AppColors.primary.withAlpha(20),
                        side: BorderSide(
                          color: AppColors.primary.withAlpha(80),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xs,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<RoomFacility>>(
      future: _facilitiesFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: AppSizes.iconXl,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Gagal memuat fasilitas',
                    style: const TextStyle(
                      fontSize: AppSizes.fontMd,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final facilities = snapshot.data ?? [];

        if (facilities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: AppSizes.iconXl,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: AppSizes.md),
                  const Text(
                    'Fasilitas tidak ditemukan',
                    style: TextStyle(
                      fontSize: AppSizes.fontMd,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: facilities.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: AppSizes.lg + AppSizes.iconMd + AppSizes.md,
          ),
          itemBuilder: (_, index) => _buildFacilityTile(facilities[index]),
        );
      },
    );
  }

  Widget _buildFacilityTile(RoomFacility facility) {
    final isSelected = _selectedFacilities.any((f) => f.id == facility.id);

    return ListTile(
      onTap: () => _toggleFacility(facility),
      tileColor: isSelected ? AppColors.primary.withAlpha(10) : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppSizes.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(25)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        ),
        child: Icon(
          facility.icon ?? Icons.devices_other,
          size: AppSizes.iconSm,
          color: isSelected ? AppColors.primary : AppColors.grey,
        ),
      ),
      title: Text(
        facility.name,
        style: TextStyle(
          fontSize: AppSizes.fontSm,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: AppSizes.iconSm,
            )
          : Icon(
              Icons.circle_outlined,
              color: AppColors.border,
              size: AppSizes.iconSm,
            ),
    );
  }
}
