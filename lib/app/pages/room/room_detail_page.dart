import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/requests/room_request.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/pages/room/facility_selector_page.dart';
import 'package:rapa_track_mobile_app/app/services/room_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_button.dart';

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
  late final TextEditingController _floorController;
  late final TextEditingController _descriptionController;

  bool _isMaintenance = false;
  bool _isSubmitting = false;

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
    _floorController = TextEditingController(
      text: _currentRoom?.floor?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: _currentRoom?.description ?? '',
    );
    _isMaintenance = _currentRoom?.isMaintenance ?? false;
    if (_currentRoom?.facilities != null) {
      _selectedFacilities.addAll(_currentRoom!.facilities!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
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
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(),
                const SizedBox(height: AppSizes.md),
                _buildFacilitiesCard(),
                const SizedBox(height: AppSizes.md),
                _buildStatusCard(),
                if (widget.editable) ...[
                  const SizedBox(height: AppSizes.lg),
                  AppButton(
                    text: 'Simpan Ruangan',
                    isFullWidth: true,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildCard(
      title: 'Informasi Dasar',
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Nama Ruangan',
          validator: _validateRoomName,
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _capacityController,
                label: 'Kapasitas (orang)',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  final cap = int.tryParse(v);
                  if (cap == null) return 'Harus angka';
                  if (cap < 1) return 'Min. 1 orang';
                  if (cap > 100) return 'Max. 100 orang';
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _buildTextField(
                controller: _floorController,
                label: 'Lantai',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  final floor = int.tryParse(v);
                  if (floor == null) return 'Harus angka';
                  if (floor < 1 || floor > 4) return 'Lantai 1–4';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        _buildTextField(
          controller: _descriptionController,
          label: 'Deskripsi (opsional)',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFacilitiesCard() {
    return _buildCard(
      title: 'Fasilitas',
      action: widget.editable
          ? TextButton.icon(
              onPressed: _openFacilitySelector,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Kelola'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            )
          : null,
      children: [
        if (_selectedFacilities.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppSizes.iconSm,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(width: AppSizes.sm),
                const Text(
                  'Belum ada fasilitas dipilih',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: _selectedFacilities.map((facility) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
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
    );
  }

  Widget _buildStatusCard() {
    if (widget.editable) {
      return _buildCard(
        title: 'Status Ruangan',
        children: [
          Container(
            decoration: BoxDecoration(
              color: _isMaintenance
                  ? AppColors.warning.withAlpha(15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: _isMaintenance
                    ? AppColors.warning.withAlpha(100)
                    : AppColors.border,
              ),
            ),
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
                horizontal: AppSizes.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: AppSizes.iconMd,
            ),
            const SizedBox(width: AppSizes.md),
            const Expanded(
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

  Widget _buildCard({
    required String title,
    Widget? action,
    required List<Widget> children,
  }) {
    return Card(
      elevation: AppSizes.elevationXs,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: AppSizes.fontLg,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppSizes.fontMd,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: AppSizes.md),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: AppSizes.fontSm,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: widget.editable ? AppColors.white : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: !widget.editable,
      validator: validator,
    );
  }

  String? _validateRoomName(String? value) {
    if (value == null || value.isEmpty) return 'Nama ruangan tidak boleh kosong';
    if (value.length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  Future<bool> _checkDuplicateName(String name) async {
    try {
      final rooms = await _service.getRoomList();
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
    if (!_formKey.currentState!.validate()) return;
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
        floor: int.tryParse(_floorController.text.trim()),
        capacity: int.tryParse(_capacityController.text.trim()),
        description: _descriptionController.text.trim(),
        isMaintenance: _isMaintenance,
        facilityIds: _selectedFacilities.map((f) => f.id).toList(),
      );

      final actionText = _currentRoom != null
          ? 'memperbarui ruangan'
          : 'menambahkan ruangan';

      if (_currentRoom != null) {
        await _service.updateRoom(roomId: _currentRoom.id!, request: request);
      } else {
        await _service.createRoom(request: request);
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
}
