import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/services/facility_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/confirm_dialog.dart';
import 'package:rapa_track_mobile_app/app/utils/validators.dart';

class FacilityManagementPage extends StatefulWidget {
  const FacilityManagementPage({super.key});

  @override
  State<FacilityManagementPage> createState() =>
      _FacilityManagementPageState();
}

class _FacilityManagementPageState extends State<FacilityManagementPage> {
  final _service = FacilityService();
  final _searchController = TextEditingController();
  late Future<List<RoomFacility>> _facilitiesFuture = _service
      .getFacilityList(forceRefresh: true);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh({String? search}) {
    setState(() {
      _facilitiesFuture = _service.getFacilityList(
        search: search,
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Fasilitas'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: Container(color: AppColors.white, child: _buildContent()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSizes.md),
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
        onChanged: (value) => _refresh(search: value),
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
          return _buildEmptyState(
            icon: Icons.error_outline,
            message: 'Gagal memuat fasilitas',
          );
        }

        final facilities = snapshot.data ?? [];

        if (facilities.isEmpty) {
          return _buildEmptyState(
            icon: Icons.devices_other,
            message: 'Belum ada fasilitas',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
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

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconXl, color: AppColors.textDisabled),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppSizes.fontMd,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityTile(RoomFacility facility) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppSizes.xs),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        ),
        child: Icon(
          facility.icon ?? Icons.devices_other,
          size: AppSizes.iconSm,
          color: AppColors.grey,
        ),
      ),
      title: Text(
        facility.name,
        style: const TextStyle(
          fontSize: AppSizes.fontSm,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: AppSizes.iconSm,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _openForm(facility: facility),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: AppSizes.iconSm,
              color: AppColors.error,
            ),
            onPressed: () => _confirmDelete(facility),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm({RoomFacility? facility}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FacilityFormDialog(facility: facility),
    );
    if (result == true) _refresh();
  }

  Future<void> _confirmDelete(RoomFacility facility) async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.delete_outline,
      iconColor: AppColors.error,
      title: 'Hapus Fasilitas',
      message: 'Apakah Anda yakin ingin menghapus "${facility.name}"?',
      confirmLabel: 'Hapus',
    );
    if (confirmed != true) return;

    try {
      await _service.deleteFacility(facility.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Gagal menghapus fasilitas: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppSizes.iconXl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Gagal',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityFormDialog extends StatefulWidget {
  final RoomFacility? facility;

  const _FacilityFormDialog({this.facility});

  @override
  State<_FacilityFormDialog> createState() => _FacilityFormDialogState();
}

class _FacilityFormDialogState extends State<_FacilityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.facility?.name,
  );
  final _service = FacilityService();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final name = _nameController.text.trim();
      if (widget.facility != null) {
        await _service.updateFacility(
          facilityId: widget.facility!.id,
          name: name,
        );
      } else {
        await _service.createFacility(name: name);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorText = '$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.facility != null;

    return AlertDialog(
      contentPadding: const EdgeInsets.all(AppSizes.xl),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Fasilitas' : 'Tambah Fasilitas',
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nama Fasilitas',
                hintText: 'Contoh: Proyektor',
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _errorText,
              ),
              validator: Validators.compose([
                Validators.required('Nama fasilitas'),
                Validators.maxLength(100, 'Nama fasilitas'),
              ]),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: AppSizes.iconSm,
                            height: AppSizes.iconSm,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
