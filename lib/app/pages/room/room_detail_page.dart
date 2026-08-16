import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/requests/room_request.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/pages/room/facility_selector_page.dart';
import 'package:rapa_track_mobile_app/app/services/room_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_button.dart';
import 'package:rapa_track_mobile_app/app/ui_items/confirm_dialog.dart';
import 'package:rapa_track_mobile_app/app/widgets/form_items.dart';

class RoomDetailPage extends StatefulWidget {
  final Profile user;
  final Room? room;
  final bool editable;

  const RoomDetailPage({super.key, required this.user, this.room})
    : editable = true;

  const RoomDetailPage.view({super.key, required this.user, this.room})
    : editable = false;

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final _service = RoomService();
  final _formKey = GlobalKey<FormState>();

  late final _currentRoom = widget.room;
  late final _isNewRoom = _currentRoom == null;

  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;

  int? _selectedFloor;
  String? _floorError;
  bool _isMaintenance = false;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  File? _imageFile;

  bool _imageRemoved = false;

  final List<RoomFacility> _selectedFacilities = [];

  @override
  void initState() {
    super.initState();
    _initializeForms();
  }

  void _initializeForms() {
    _nameController = TextEditingController(text: _currentRoom?.name);
    _capacityController = TextEditingController(
      text: _currentRoom?.capacity?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: _currentRoom?.description ?? '',
    );
    _selectedFloor = _currentRoom?.floor;
    _isMaintenance = _currentRoom?.isMaintenance ?? false;
    if (_currentRoom?.facilities != null) {
      _selectedFacilities.addAll(_currentRoom!.facilities!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap tunggu hingga proses selesai...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _isNewRoom
                ? 'Tambah Ruangan'
                : (widget.editable ? 'Edit Ruangan' : 'Detail Ruangan'),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('Informasi Dasar'),
                  _buildInfoSection(),
                  const SizedBox(height: AppSizes.xl),
                  const SectionLabel('Lantai'),
                  _buildFloorSection(),
                  if (_floorError != null) _buildFloorError(),
                  const SizedBox(height: AppSizes.xl),
                  if (widget.editable || _currentRoom?.hasImage == true) ...[
                    const SectionLabel('Gambar Ruangan'),
                    widget.editable
                        ? _buildImageEditorSection()
                        : _buildImageSection(),
                    const SizedBox(height: AppSizes.xl),
                  ],
                  const SectionLabel('Fasilitas'),
                  _buildFacilitiesSection(),
                  const SizedBox(height: AppSizes.xl),
                  _buildStatusSection(),
                  if (widget.editable) ...[
                    const SizedBox(height: AppSizes.xl),
                    AppButton(
                      text: 'Simpan Ruangan',
                      isFullWidth: true,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                    if (!_isNewRoom) ...[
                      const SizedBox(height: AppSizes.md),
                      AppButton(
                        text: 'Hapus Ruangan',
                        isFullWidth: true,
                        isOutlined: true,
                        color: AppColors.error,
                        isLoading: _isDeleting,
                        onPressed: _isSubmitting || _isDeleting
                            ? null
                            : _confirmDelete,
                      ),
                    ],
                    const SizedBox(height: AppSizes.xxl),
                  ] else if (!_isNewRoom) ...[
                    const SizedBox(height: AppSizes.xl),
                    AppButton(
                      text: 'Edit Ruangan',
                      isFullWidth: true,
                      icon: Icons.edit_outlined,
                      onPressed: _navigateToEdit,
                    ),
                    const SizedBox(height: AppSizes.xxl),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftTextField(
          controller: _nameController,
          hint: 'Nama ruangan',
          readOnly: !widget.editable,
          validator: _validateRoomName,
        ),
        const SizedBox(height: AppSizes.md),
        SoftTextField(
          controller: _capacityController,
          hint: 'Kapasitas',
          suffixText: 'orang',
          keyboardType: TextInputType.number,
          readOnly: !widget.editable,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Kapasitas wajib diisi';
            final cap = int.tryParse(v);
            if (cap == null) return 'Harus angka';
            if (cap < 1) return 'Min. 1 orang';
            if (cap > 100) return 'Max. 100 orang';
            return null;
          },
        ),
        const SizedBox(height: AppSizes.md),
        SoftTextField(
          controller: _descriptionController,
          hint: 'Deskripsi (opsional)',
          maxLines: 3,
          readOnly: !widget.editable,
        ),
      ],
    );
  }

  Widget _buildFloorSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFloorCard(1)),
            const SizedBox(width: AppSizes.md),
            Expanded(child: _buildFloorCard(2)),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(child: _buildFloorCard(3)),
            const SizedBox(width: AppSizes.md),
            Expanded(child: _buildFloorCard(4)),
          ],
        ),
      ],
    );
  }

  Widget _buildFloorCard(int floor) {
    return ChoiceCard(
      label: 'Lantai $floor',
      isSelected: _selectedFloor == floor,
      onTap: widget.editable
          ? () => setState(() {
              _selectedFloor = floor;
              _floorError = null;
            })
          : null,
    );
  }

  Widget _buildFloorError() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.sm),
      child: Text(
        _floorError!,
        style: const TextStyle(
          fontSize: AppSizes.fontXs,
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Fasilitas Ruangan',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (widget.editable)
                GestureDetector(
                  onTap: _openFacilitySelector,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: AppSizes.iconXs,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSizes.xs),
                      Text(
                        'Kelola',
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (_selectedFacilities.isEmpty)
            const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppSizes.iconSm,
                  color: AppColors.textDisabled,
                ),
                SizedBox(width: AppSizes.sm),
                Text(
                  'Belum ada fasilitas dipilih',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: _selectedFacilities.map((facility) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (facility.icon != null) ...[
                        Icon(
                          facility.icon,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSizes.xxs),
                      ],
                      Text(
                        facility.name,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    if (widget.editable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Status Ruangan'),
          SoftCard(
            padding: EdgeInsets.zero,
            color: _isMaintenance
                ? AppColors.warning.withAlpha(15)
                : AppColors.white,
            child: SwitchListTile(
              title: const Text(
                'Sedang Maintenance',
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _isMaintenance
                    ? 'Ruangan tidak dapat dipesan saat ini'
                    : 'Ruangan tersedia untuk reservasi',
                style: TextStyle(
                  fontSize: AppSizes.fontXs,
                  color: _isMaintenance
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
              ),
              value: _isMaintenance,
              activeThumbColor: AppColors.warning,
              activeTrackColor: AppColors.warning.withAlpha(128),
              onChanged: (val) => setState(() => _isMaintenance = val),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
          ),
        ],
      );
    }

    if (_currentRoom?.isMaintenance ?? false) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(20),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.warning.withAlpha(100)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: AppSizes.iconMd,
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dalam Perawatan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                      fontSize: AppSizes.fontSm,
                    ),
                  ),
                  SizedBox(height: AppSizes.xxs),
                  Text(
                    'Ruangan ini sedang dalam perawatan dan tidak dapat dipesan.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: AppSizes.fontXs,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String? _validateRoomName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama ruangan tidak boleh kosong';
    }
    if (value.length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  Future<bool> _checkDuplicateName(String name) async {
    try {
      final rooms = await _service.getRoomList(
        search: name,
        perPage: 50,
      );
      final lowerName = name.toLowerCase().trim();
      return rooms.any((room) {
        return room.name?.toLowerCase() == lowerName &&
            room.id != _currentRoom?.id;
      });
    } catch (_) {
      return false;
    }
  }

  Future<void> _openFacilitySelector() async {
    final result = await Navigator.of(context).push<List<RoomFacility>>(
      MaterialPageRoute(
        builder: (_) => FacilitySelectorPage(
          initialSelectedFacilities: _selectedFacilities,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedFacilities.clear();
        _selectedFacilities.addAll(result);
      });
    }
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState!.validate();

    if (_selectedFloor == null) {
      setState(() => _floorError = 'Silakan pilih lantai ruangan');
    }

    if (!isFormValid || _selectedFloor == null) return;

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final isDuplicate = await _checkDuplicateName(name);

      if (isDuplicate && mounted) {
        _showStatusDialog(
          title: 'Nama Sudah Digunakan',
          message: 'Nama ruangan "$name" sudah ada. Gunakan nama yang berbeda.',
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warning,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final request = RoomRequest(
        name: name,
        floor: _selectedFloor,
        capacity: int.tryParse(_capacityController.text.trim()),
        description: _descriptionController.text.trim(),
        isMaintenance: _isMaintenance,
        facilityIds: _selectedFacilities.map((f) => f.id).toList(),
      );

      final actionText = _currentRoom != null
          ? 'memperbarui ruangan'
          : 'menambahkan ruangan';

      String? roomId = _currentRoom?.id;

      if (_currentRoom != null) {
        await _service.updateRoom(roomId: _currentRoom.id!, request: request);
      } else {
        final created = await _service.createRoom(request: request);
        roomId = created.id;
      }

      if (_imageFile != null && roomId != null) {
        await _service.uploadImage(
          roomId: roomId,
          image: _imageFile!,
        );
      }

      if (mounted) {
        await _showStatusDialog(
          title: 'Berhasil',
          message: 'Berhasil $actionText.',
          icon: Icons.check_circle,
          iconColor: AppColors.success,
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(
          title: 'Gagal Menyimpan',
          message: 'Terjadi kesalahan: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _navigateToEdit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(user: widget.user, room: _currentRoom),
      ),
    );
    if (changed == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.delete_outline,
      iconColor: AppColors.error,
      title: 'Hapus Ruangan',
      message:
          'Apakah Anda yakin ingin menghapus ruangan "${_currentRoom!.name}"? Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await _service.deleteRoom(_currentRoom.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showStatusDialog(
          title: 'Gagal Menghapus',
          message: 'Terjadi kesalahan: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _showStatusDialog({
    required String title,
    required String message,
    IconData icon = Icons.error_outline,
    Color iconColor = AppColors.error,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: AppSizes.iconXl),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
            AppButton(
              text: 'OK',
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final url = _currentRoom?.imageUrl;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, error, stackTrace) {
                  return _buildImagePlaceholder(
                    Icons.broken_image,
                    'Gambar tidak dapat dimuat',
                  );
                },
              )
            : _buildImagePlaceholder(
                Icons.meeting_room_outlined,
                'Belum ada foto ruangan',
              ),
      ),
    );
  }

  Widget _buildImageEditorSection() {
    final hasExistingImage =
        !_imageRemoved && _currentRoom?.hasImage == true && !_isNewRoom;
    final canDelete = _imageFile != null || hasExistingImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _imageFile != null
                    ? Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : (hasExistingImage
                          ? Image.network(
                              _currentRoom!.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, error, stackTrace) {
                                return _buildImagePlaceholder(
                                  Icons.broken_image,
                                  'Gambar tidak dapat dimuat',
                                );
                              },
                            )
                          : _buildImagePlaceholder(
                              Icons.meeting_room_outlined,
                              'Belum ada foto ruangan',
                            )),
                if (canDelete)
                  Positioned(
                    top: AppSizes.sm,
                    right: AppSizes.sm,
                    child: GestureDetector(
                      onTap: _isSubmitting ? null : _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.xs),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: AppSizes.iconXs,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _showImageSourceSheet,
          icon: const Icon(
            Icons.photo_camera_outlined,
            size: AppSizes.iconSm,
          ),
          label: const Text('Ganti Foto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSourceSheet() async {
    final hasExistingImage =
        !_imageRemoved && _currentRoom?.hasImage == true && !_isNewRoom;
    final canDelete = _imageFile != null || hasExistingImage;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.md,
            AppSizes.sm,
            AppSizes.md,
            AppSizes.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
                  ),
                ),
              ),
              _buildSheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Ambil dari Kamera',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              _buildSheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Pilih dari Galeri',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (canDelete)
                _buildSheetOption(
                  icon: Icons.delete_outline,
                  label: 'Hapus Foto',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _removeImage();
                  },
                ),
              const SizedBox(height: AppSizes.xs),
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.textPrimary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: AppSizes.fontSm,
          fontWeight: FontWeight.w500,
          color: effectiveColor,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      onTap: onTap,
    );
  }

  Widget _buildImagePlaceholder(IconData icon, String label) {
    return Container(
      color: AppColors.lightGrey,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconXl, color: AppColors.textDisabled),
            const SizedBox(height: AppSizes.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 35,
      );
      if (picked != null && mounted) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _removeImage() async {
    setState(() => _imageFile = null);

    if (_isNewRoom) return;

    if (!_currentRoom!.hasImage) return;

    final roomId = _currentRoom.id;
    if (roomId == null) return;

    try {
      await _service.deleteImage(roomId);
      if (mounted) {
        setState(() => _imageRemoved = true);
        _showStatusDialog(
          title: 'Berhasil',
          message: 'Foto ruangan berhasil dihapus.',
          icon: Icons.check_circle,
          iconColor: AppColors.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(
          title: 'Gagal Menghapus Foto',
          message: 'Terjadi kesalahan: $e',
        );
      }
    }
  }
}
