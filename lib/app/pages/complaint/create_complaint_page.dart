import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/services/complaint_service.dart';
import 'package:rapa_track_mobile_app/app/services/facility_service.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class CreateComplaintPage extends StatefulWidget {
  final Profile user;

  const CreateComplaintPage({super.key, required this.user});

  @override
  State<CreateComplaintPage> createState() => _CreateComplaintPageState();
}

class _CreateComplaintPageState extends State<CreateComplaintPage> {
  final _complaintService = ComplaintService();
  final _reservationService = ReservationService();
  final _facilityService = FacilityService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Reservation? _selectedReservation;
  RoomFacility? _selectedFacility;
  File? _photoFile;
  bool _isSubmitting = false;

  List<Reservation> _completedReservations = [];
  List<RoomFacility> _facilities = [];
  bool _isLoadingReservations = true;
  bool _isLoadingFacilities = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadReservations(), _loadFacilities()]);
  }

  Future<void> _loadReservations() async {
    try {
      final result = await _reservationService.getReservationList(
        status: 'completed',
      );
      if (mounted) {
        setState(() {
          _completedReservations = result.reservations;
          _isLoadingReservations = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReservations = false);
    }
  }

  Future<void> _loadFacilities() async {
    setState(() => _isLoadingFacilities = true);
    try {
      final result = await _facilityService.getFacilityList();
      if (mounted) {
        setState(() {
          _facilities = result;
          _isLoadingFacilities = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFacilities = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Keluhan'),
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
              _buildInfoBanner(),
              const SizedBox(height: AppSizes.xl),
              _buildReservationSelector(),
              const SizedBox(height: AppSizes.lg),
              _buildFacilitySelector(),
              const SizedBox(height: AppSizes.lg),
              _buildTitleField(),
              const SizedBox(height: AppSizes.lg),
              _buildDescriptionField(),
              const SizedBox(height: AppSizes.lg),
              _buildPhotoSection(),
              const SizedBox(height: AppSizes.xxl),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              'Keluhan hanya dapat dibuat untuk reservasi yang sudah selesai',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Reservasi *',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        InkWell(
          onTap: _isSubmitting ? null : _showReservationSelector,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedReservation != null
                    ? AppColors.primary
                    : AppColors.border,
                width: _selectedReservation != null
                    ? AppSizes.borderWidthThick
                    : AppSizes.borderWidth,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: _isLoadingReservations
                ? const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: AppSizes.md),
                      Text('Memuat reservasi...'),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.event_available,
                          color: AppColors.primary,
                          size: AppSizes.iconMd,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _selectedReservation != null
                            ? _buildSelectedReservationInfo()
                            : Text(
                                _completedReservations.isEmpty
                                    ? 'Tidak ada reservasi selesai'
                                    : 'Pilih reservasi',
                                style: const TextStyle(
                                  fontSize: AppSizes.fontSm,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: AppSizes.iconXs,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedReservationInfo() {
    final r = _selectedReservation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.room?.name ?? 'Ruangan',
          style: const TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.xxs),
        Text(
          r.formattedRange,
          style: const TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.textSecondary,
          ),
        ),
        if (r.purpose != null && r.purpose!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.xxs),
          Text(
            r.purpose!,
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildFacilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fasilitas Bermasalah (opsional)',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        InkWell(
          onTap: (_isSubmitting || _isLoadingFacilities)
              ? null
              : _showFacilitySelector,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    _selectedFacility?.icon ?? Icons.build_outlined,
                    color: AppColors.textSecondary,
                    size: AppSizes.iconMd,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _isLoadingFacilities
                      ? const Text(
                          'Memuat fasilitas...',
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Text(
                          _selectedFacility?.name ?? 'Tidak dipilih',
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: _selectedFacility != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: AppSizes.iconXs,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keluhan *',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: _titleController,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Contoh: AC tidak dingin, Proyektor mati',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Judul keluhan tidak boleh kosong';
            }
            if (value.trim().length < 5) {
              return 'Judul minimal 5 karakter';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail yang jadi keluhan *',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Jelaskan masalah yang Anda temui secara detail...',
            border: OutlineInputBorder(),
            helperText: 'Minimal 10 karakter',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Deskripsi tidak boleh kosong';
            }
            if (value.trim().length < 10) {
              return 'Deskripsi minimal 10 karakter';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Bukti (opsional)',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        if (_photoFile != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: Image.file(
                  _photoFile!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: AppSizes.xs,
                right: AppSizes.xs,
                child: GestureDetector(
                  onTap: () => setState(() => _photoFile = null),
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
          const SizedBox(height: AppSizes.sm),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  size: AppSizes.iconSm,
                ),
                label: const Text('Kamera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(
                  Icons.photo_library_outlined,
                  size: AppSizes.iconSm,
                ),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitComplaint,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
      child: _isSubmitting
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
                SizedBox(width: AppSizes.md),
                Text('Mengirim...'),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send),
                SizedBox(width: AppSizes.sm),
                Text(
                  'Kirim Keluhan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }

  Future<void> _showReservationSelector() async {
    if (_completedReservations.isEmpty) {
      _showDialog(
        icon: Icons.event_busy,
        iconColor: AppColors.warning,
        title: 'Tidak Ada Reservasi',
        message:
            'Anda belum memiliki reservasi yang selesai. Keluhan hanya dapat dibuat untuk reservasi berstatus selesai.',
      );
      return;
    }

    final selected = await showModalBottomSheet<Reservation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => _buildReservationSheet(),
    );

    if (selected != null) {
      setState(() => _selectedReservation = selected);
    }
  }

  Widget _buildReservationSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          _buildSheetHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.xl,
              AppSizes.xs,
              AppSizes.xl,
              AppSizes.md,
            ),
            child: Text(
              'Pilih Reservasi',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: _completedReservations.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
              itemBuilder: (context, index) {
                final r = _completedReservations[index];
                final isSelected = _selectedReservation?.id == r.id;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(r),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(15)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.room?.name ?? 'Ruangan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppSizes.fontSm,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.xxs),
                              Text(
                                r.formattedRange,
                                style: const TextStyle(
                                  fontSize: AppSizes.fontXs,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (r.purpose != null &&
                                  r.purpose!.isNotEmpty) ...[
                                const SizedBox(height: AppSizes.xxs),
                                Text(
                                  r.purpose!,
                                  style: const TextStyle(
                                    fontSize: AppSizes.fontXs,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: AppSizes.iconSm,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFacilitySelector() async {
    if (_facilities.isEmpty) return;

    final selected = await showModalBottomSheet<RoomFacility?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => _buildFacilitySheet(),
    );

    if (selected != null || (selected == null && mounted)) {
      setState(() => _selectedFacility = selected);
    }
  }

  Widget _buildFacilitySheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          _buildSheetHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.xl,
              AppSizes.xs,
              AppSizes.xl,
              AppSizes.md,
            ),
            child: Text(
              'Pilih Fasilitas',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                _buildFacilityOption(null),
                const SizedBox(height: AppSizes.xs),
                ..._facilities.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.xs),
                    child: _buildFacilityOption(f),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityOption(RoomFacility? facility) {
    final isSelected = facility == null
        ? _selectedFacility == null
        : _selectedFacility?.id == facility.id;

    return InkWell(
      onTap: () => Navigator.of(context).pop(facility),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(15) : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              facility?.icon ?? Icons.not_interested,
              size: AppSizes.iconSm,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Text(
                facility?.name ?? 'Tidak dipilih',
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: AppSizes.iconSm,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _photoFile = File(picked.path));
      }
    } catch (_) {}
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          ),
        ),
      ),
    );
  }

  void _showDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String buttonText = 'Tutup',
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(icon, color: iconColor, size: 40),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onPressed ?? () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedReservation == null) {
      _showDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warning,
        title: 'Pilih Reservasi',
        message: 'Silakan pilih reservasi terlebih dahulu',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _complaintService.createComplaint(
        reservationId: _selectedReservation!.id!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        facilityId: _selectedFacility?.id,
        photo: _photoFile,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 40,
          ),
          title: const Text('Keluhan Terkirim'),
          content: const Text(
            'Keluhan berhasil dikirim. Tim kami akan segera menangani.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showDialog(
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        title: 'Gagal Mengirim',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
