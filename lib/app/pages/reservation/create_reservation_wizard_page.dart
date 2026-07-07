import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/room_selector_section.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/user_selector_section.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_snackbar.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
import 'package:rapa_track_mobile_app/app/widgets/form_items.dart';

class CreateReservationWizardPage extends StatefulWidget {
  final Profile currentUser;
  final DateTime? initialDate;
  final Room? initialRoom;

  const CreateReservationWizardPage({
    super.key,
    required this.currentUser,
    this.initialDate,
    this.initialRoom,
  });

  @override
  State<CreateReservationWizardPage> createState() =>
      _CreateReservationWizardPageState();
}

class _CreateReservationWizardPageState
    extends State<CreateReservationWizardPage> {
  final _reservationService = ReservationService();
  final _purposeController = TextEditingController();
  final _pageController = PageController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Room? _selectedRoom;
  Profile? _selectedUser;
  int _visitorCount = 1;
  bool _withSnack = false;
  bool _withLunch = false;
  late final TextEditingController _visitorCountController;

  bool get _isAdmin => widget.currentUser.isAdmin;

  DateTime? get _startDateTime {
    if (_selectedDate == null || _startTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
  }

  DateTime? get _endDateTime {
    if (_selectedDate == null || _endTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialDate != null) {
      _selectedDate = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
      );
    }

    if (widget.initialRoom != null) {
      _selectedRoom = widget.initialRoom;
    }

    _visitorCountController = TextEditingController(text: '$_visitorCount');
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _pageController.dispose();
    _visitorCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Reservasi Baru'), elevation: 0),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildStep1DateTimeSelection(),
                  _buildStep2RoomSelection(),
                  _buildStep3Details(),
                  _buildStep4Review(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepDot(0, 'Waktu'),
          _buildStepLine(0),
          _buildStepDot(1, 'Ruangan'),
          _buildStepLine(1),
          _buildStepDot(2, 'Detail'),
          _buildStepLine(2),
          _buildStepDot(3, 'Review'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.success
                  : isActive
                  ? AppColors.primary
                  : AppColors.lightGrey,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: AppSizes.fontLg,
                    )
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.fontSm,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? AppColors.primary
                  : isCompleted
                  ? AppColors.success
                  : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: AppSizes.borderWidthThick,
        margin: const EdgeInsets.only(bottom: AppSizes.xl),
        color: isCompleted ? AppColors.success : AppColors.lightGrey,
      ),
    );
  }

  Widget _buildStep1DateTimeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pilih Tanggal & Waktu',
            style: TextStyle(
              fontSize: AppSizes.fontXxl,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'Tentukan kapan Anda membutuhkan ruangan',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          if (_isAdmin) ...[
            _buildUserSelectorCard(),
            const SizedBox(height: AppSizes.lg),
          ],

          _buildDateSelectorCard(),
          const SizedBox(height: AppSizes.lg),

          Row(
            children: [
              Expanded(child: _buildStartTimeCard()),
              const SizedBox(width: AppSizes.md),
              Expanded(child: _buildEndTimeCard()),
            ],
          ),

          if (_startTime != null && _endTime != null) ...[
            const SizedBox(height: AppSizes.lg),
            _buildDurationInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserSelectorCard() {
    return SoftCard(
      onTap: _showUserSelector,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSizes.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reservasi untuk',
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  _selectedUser?.name ?? 'Pilih Karyawan',
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: _selectedUser != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selectedUser != null
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: AppSizes.iconXs,
            color: AppColors.textDisabled,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectorCard() {
    return SoftCard(
      onTap: _selectDate,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSizes.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal',
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  _selectedDate != null
                      ? DateFormatter.longDate(_selectedDate!)
                      : 'Pilih Tanggal',
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: _selectedDate != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selectedDate != null
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: AppSizes.iconXs,
            color: AppColors.textDisabled,
          ),
        ],
      ),
    );
  }

  Widget _buildStartTimeCard() {
    final isEnabled = _selectedDate != null;

    return SoftCard(
      color: isEnabled ? AppColors.white : AppColors.background,
      onTap: isEnabled ? _selectStartTime : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: isEnabled ? AppColors.primary : AppColors.textDisabled,
                size: AppSizes.iconSm,
              ),
              const SizedBox(width: AppSizes.sm),
              const Text(
                'Mulai',
                style: TextStyle(
                  fontSize: AppSizes.fontXs,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            _startTime != null ? _formatTime(_startTime!) : '--:--',
            style: TextStyle(
              fontSize: AppSizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: _startTime != null && isEnabled
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndTimeCard() {
    final isEnabled = _selectedDate != null && _startTime != null;

    return SoftCard(
      color: isEnabled ? AppColors.white : AppColors.background,
      onTap: isEnabled ? _selectEndTime : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: isEnabled ? AppColors.primary : AppColors.textDisabled,
                size: AppSizes.iconSm,
              ),
              const SizedBox(width: AppSizes.sm),
              const Text(
                'Selesai',
                style: TextStyle(
                  fontSize: AppSizes.fontXs,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            _endTime != null ? _formatTime(_endTime!) : '--:--',
            style: TextStyle(
              fontSize: AppSizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: _endTime != null && isEnabled
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo() {
    final duration = _calculateDuration();
    if (duration == null) return const SizedBox.shrink();

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule,
            color: AppColors.info,
            size: AppSizes.iconSm,
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            'Durasi: ${hours > 0 ? '$hours jam' : ''} ${minutes > 0 ? '$minutes menit' : ''}',
            style: const TextStyle(
              color: AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2RoomSelection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Ruangan',
                  style: TextStyle(
                    fontSize: AppSizes.fontXxl,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                const Text(
                  'Ruangan tersedia untuk waktu yang dipilih',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _selectedRoom == null
                    ? _buildRoomSelectorPlaceholder()
                    : _buildSelectedRoomCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelectorPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.meeting_room_outlined,
            size: 80,
            color: AppColors.lightGrey,
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'Belum ada ruangan dipilih',
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'Ketuk tombol di bawah untuk memilih',
            style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.grey),
          ),
          const SizedBox(height: AppSizes.xl),
          ElevatedButton.icon(
            onPressed: _showRoomSelector,
            icon: const Icon(Icons.add),
            label: const Text('Pilih Ruangan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRoomCard() {
    final room = _selectedRoom!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        children: [
          Card(
            elevation: AppSizes.elevationMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radiusSm),
                    ),
                  ),
                  child: room.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSizes.radiusSm),
                          ),
                          child: Image.network(
                            room.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildRoomPlaceholder(),
                          ),
                        )
                      : _buildRoomPlaceholder(),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name ?? 'Ruangan',
                        style: const TextStyle(
                          fontSize: AppSizes.fontXl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: AppSizes.iconXs,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            room.location,
                            style: const TextStyle(
                              fontSize: AppSizes.fontSm,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSizes.lg),
                          const Icon(
                            Icons.people,
                            size: AppSizes.iconXs,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            'Kapasitas: ${room.capacity ?? 0} orang',
                            style: const TextStyle(
                              fontSize: AppSizes.fontSm,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (room.description != null &&
                          room.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.md),
                        Text(
                          room.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                      if (room.facilities != null &&
                          room.facilities!.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.md),
                        Wrap(
                          spacing: AppSizes.sm,
                          runSpacing: AppSizes.sm,
                          children: room.facilities!
                              .map(
                                (f) => Chip(
                                  label: Text(
                                    f.name,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.sm,
                                    vertical: 0,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          OutlinedButton.icon(
            onPressed: _showRoomSelector,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Ganti Ruangan'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomPlaceholder() {
    return const Center(
      child: Icon(
        Icons.meeting_room,
        size: AppSizes.avatarXl,
        color: AppColors.textDisabled,
      ),
    );
  }

  Widget _buildStep3Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Detail Reservasi',
            style: TextStyle(
              fontSize: AppSizes.fontXxl,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'Lengkapi informasi reservasi Anda',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          _buildPurposeField(),
          const SizedBox(height: AppSizes.lg),
          _buildVisitorCountCard(),
          const SizedBox(height: AppSizes.lg),
          _buildMealOptionsCard(),
        ],
      ),
    );
  }

  Widget _buildPurposeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Tujuan Rapat'),
        SoftTextField(
          controller: _purposeController,
          hint: 'Contoh: Rapat koordinasi tim marketing Q2 2026',
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          helperText: 'Jelaskan tujuan penggunaan ruangan',
        ),
      ],
    );
  }

  Widget _buildVisitorCountCard() {
    final maxCapacity = _selectedRoom?.capacity ?? 100;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people, color: AppColors.primary),
              SizedBox(width: AppSizes.sm),
              Text(
                'Jumlah Peserta',
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filled(
                onPressed: _visitorCount > 1
                    ? () => setState(() {
                        _visitorCount--;
                        _visitorCountController.text = '$_visitorCount';
                      })
                    : null,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _visitorCountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXxl,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: AppSizes.sm),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed >= 1) {
                      final clamped = parsed.clamp(1, maxCapacity);
                      setState(() => _visitorCount = clamped.toInt());
                      if (clamped != parsed) {
                        _visitorCountController.text = '$clamped';
                        _visitorCountController.selection =
                            TextSelection.fromPosition(
                              TextPosition(
                                offset: _visitorCountController.text.length,
                              ),
                            );
                      }
                    }
                  },
                  onSubmitted: (value) {
                    final parsed = int.tryParse(value) ?? 1;
                    final clamped = parsed.clamp(1, maxCapacity);
                    setState(() => _visitorCount = clamped.toInt());
                    _visitorCountController.text = '$clamped';
                  },
                ),
              ),
              IconButton.filled(
                onPressed: _visitorCount < maxCapacity
                    ? () => setState(() {
                        _visitorCount++;
                        _visitorCountController.text = '$_visitorCount';
                      })
                    : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          if (_selectedRoom?.capacity != null) ...[
            const SizedBox(height: AppSizes.sm),
            Center(
              child: Text(
                'Kapasitas maksimal: ${_selectedRoom!.capacity} orang',
                style: const TextStyle(
                  fontSize: AppSizes.fontXs,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealOptionsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Kebutuhan Konsumsi'),
        Row(
          children: [
            Expanded(
              child: CheckCard(
                label: 'Snack',
                icon: Icons.cookie_outlined,
                isSelected: _withSnack,
                onTap: () => setState(() => _withSnack = !_withSnack),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: CheckCard(
                label: 'Makan Siang',
                icon: Icons.lunch_dining_outlined,
                isSelected: _withLunch,
                onTap: () => setState(() => _withLunch = !_withLunch),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4Review() {
    final meals = [
      if (_withSnack) 'Snack',
      if (_withLunch) 'Makan Siang',
    ].join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Review Reservasi',
            style: TextStyle(
              fontSize: AppSizes.fontXxl,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'Periksa kembali detail reservasi Anda',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isAdmin && _selectedUser != null) ...[
                  _buildReviewItem(
                    icon: Icons.person,
                    label: 'Reservasi untuk',
                    value: _selectedUser!.name,
                  ),
                  const Divider(height: AppSizes.xl),
                ],

                _buildReviewItem(
                  icon: Icons.calendar_today,
                  label: 'Tanggal',
                  value: _selectedDate != null
                      ? DateFormatter.longDate(_selectedDate!)
                      : '-',
                ),
                const Divider(height: AppSizes.xl),

                _buildReviewItem(
                  icon: Icons.access_time,
                  label: 'Waktu',
                  value: _startTime != null && _endTime != null
                      ? '${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}'
                      : '-',
                ),
                const Divider(height: AppSizes.xl),

                _buildReviewItem(
                  icon: Icons.meeting_room,
                  label: 'Ruangan',
                  value: _selectedRoom?.name ?? '-',
                ),
                const Divider(height: AppSizes.xl),

                _buildReviewItem(
                  icon: Icons.people,
                  label: 'Jumlah Peserta',
                  value: '$_visitorCount orang',
                ),
                const Divider(height: AppSizes.xl),

                _buildReviewItem(
                  icon: Icons.description,
                  label: 'Tujuan',
                  value: _purposeController.text.isEmpty
                      ? '(Belum diisi)'
                      : _purposeController.text,
                ),
                const Divider(height: AppSizes.xl),

                _buildReviewItem(
                  icon: Icons.restaurant_menu,
                  label: 'Konsumsi',
                  value: meals.isEmpty ? 'Tidak ada' : meals,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.xl),

          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.8),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: AppSizes.iconMd,
                ),
                SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    'Reservasi Anda akan menunggu persetujuan admin sebelum dapat digunakan.',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: AppSizes.iconSm),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppSizes.fontXs,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(18),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.buttonHeightLg),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppSizes.md),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _nextStep,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: AppSizes.iconSm,
                      height: AppSizes.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : Icon(_currentStep < 3 ? Icons.arrow_forward : Icons.check),
              label: Text(
                _isSubmitting
                    ? 'Memproses...'
                    : _currentStep < 3
                    ? 'Lanjut'
                    : 'Buat Reservasi',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, AppSizes.buttonHeightLg),
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitReservation();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedDate == null) {
          AppSnackBar.show(
            context,
            'Silakan pilih tanggal terlebih dahulu',
            type: SnackBarType.error,
          );
          return false;
        }
        if (_startTime == null) {
          AppSnackBar.show(
            context,
            'Silakan pilih waktu mulai',
            type: SnackBarType.error,
          );
          return false;
        }
        if (_endTime == null) {
          AppSnackBar.show(
            context,
            'Silakan pilih waktu selesai',
            type: SnackBarType.error,
          );
          return false;
        }
        if (_isAdmin && _selectedUser == null) {
          AppSnackBar.show(
            context,
            'Silakan pilih karyawan untuk reservasi',
            type: SnackBarType.error,
          );
          return false;
        }
        return true;

      case 1:
        if (_selectedRoom == null) {
          AppSnackBar.show(
            context,
            'Silakan pilih ruangan',
            type: SnackBarType.error,
          );
          return false;
        }
        return true;

      case 2:
        if (_purposeController.text.trim().isEmpty) {
          AppSnackBar.show(
            context,
            'Silakan isi tujuan/agenda rapat',
            type: SnackBarType.error,
          );
          return false;
        }
        if (_visitorCount < 1) {
          AppSnackBar.show(
            context,
            'Jumlah peserta minimal 1 orang',
            type: SnackBarType.error,
          );
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  Future<void> _submitReservation() async {
    if (_startDateTime == null ||
        _endDateTime == null ||
        _selectedRoom == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reservationService.createReservation(
        roomId: _selectedRoom!.id!,
        startTime: _startDateTime!,
        endTime: _endDateTime!,
        purpose: _purposeController.text.trim(),
        visitorCount: _visitorCount,
        userId: _selectedUser?.id,
        withSnack: _withSnack,
        withLunch: _withLunch,
      );

      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Reservasi berhasil dibuat! Menunggu persetujuan admin.',
        type: SnackBarType.success,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Gagal membuat reservasi: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      confirmText: 'OK',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_selectedRoom != null) _selectedRoom = null;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final initialTime =
        _startTime ?? TimeOfDay(hour: (now.hour + 1).clamp(0, 23), minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Pilih Waktu Mulai',
      cancelText: 'Batal',
      confirmText: 'OK',
      builder: (_, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked != null) {
      if (_selectedDate != null) {
        final isToday =
            _selectedDate!.year == now.year &&
            _selectedDate!.month == now.month &&
            _selectedDate!.day == now.day;

        if (isToday) {
          final selectedDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            picked.hour,
            picked.minute,
          );

          if (selectedDateTime.isBefore(now)) {
            if (!mounted) return;
            AppSnackBar.show(
              context,
              'Waktu mulai tidak boleh di masa lalu',
              type: SnackBarType.error,
            );
            return;
          }
        }
      }

      setState(() {
        _startTime = picked;
        if (_endTime != null && !_isTimeAfter(_endTime!, picked)) {
          _endTime = null;
        }
        if (_selectedRoom != null) _selectedRoom = null;
      });

      if (_endTime == null && mounted) {
        await _selectEndTime();
      }
    }
  }

  Future<void> _selectEndTime() async {
    if (_startTime == null) return;

    final initialTime =
        _endTime ??
        TimeOfDay(
          hour: (_startTime!.hour + 1).clamp(0, 23),
          minute: _startTime!.minute,
        );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Pilih Waktu Selesai',
      cancelText: 'Batal',
      confirmText: 'OK',
      builder: (_, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked != null) {
      if (!_isTimeAfter(picked, _startTime!)) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          'Waktu selesai harus setelah waktu mulai',
          type: SnackBarType.error,
        );
        return;
      }

      setState(() {
        _endTime = picked;
        if (_selectedRoom != null) _selectedRoom = null;
      });
    }
  }

  Future<void> _showUserSelector() async {
    final selectedUser = await UserSelectorSection.showBottomSheet(
      context: context,
      selectedUserId: _selectedUser?.id,
    );

    if (selectedUser != null) setState(() => _selectedUser = selectedUser);
  }

  Future<void> _showRoomSelector() async {
    if (_startDateTime == null || _endDateTime == null) {
      AppSnackBar.show(
        context,
        'Silakan pilih tanggal & waktu terlebih dahulu',
        type: SnackBarType.warning,
      );
      return;
    }

    final selectedRoom = await RoomSelectorSection.showBottomSheet(
      context: context,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      selectedRoomId: _selectedRoom?.id,
    );

    if (selectedRoom != null) setState(() => _selectedRoom = selectedRoom);
  }

  String _formatTime(TimeOfDay time) => DateFormatter.formatTimeOfDay(time);

  bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour > time2.hour) return true;
    if (time1.hour == time2.hour && time1.minute > time2.minute) return true;
    return false;
  }

  Duration? _calculateDuration() {
    if (_startTime == null || _endTime == null) return null;
    final start = Duration(
      hours: _startTime!.hour,
      minutes: _startTime!.minute,
    );
    final end = Duration(hours: _endTime!.hour, minutes: _endTime!.minute);
    return end - start;
  }
}
