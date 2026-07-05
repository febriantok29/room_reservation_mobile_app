import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/room_selector_section.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/user_selector_section.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_snackbar.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';

/// Wizard untuk membuat reservasi baru dengan langkah-langkah yang user-friendly
///
/// Flow:
/// 1. Pilih Tanggal & Waktu
/// 2. Pilih Ruangan (berdasarkan availability)
/// 3. Isi Detail Reservasi (purpose, visitor count)
/// 4. Review & Konfirmasi
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

  // Wizard state
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form data
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Room? _selectedRoom;
  Profile? _selectedUser; // Hanya untuk admin
  int _visitorCount = 1;

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

    // Set initial values
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
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Reservasi Baru'), elevation: 0),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
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
    );
  }

  /// Step Indicator (Progress Bar)
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.success
                  : isActive
                  ? AppColors.primary
                  : Colors.grey.shade300,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? AppColors.primary
                  : isCompleted
                  ? AppColors.success
                  : Colors.grey.shade600,
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
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isCompleted ? AppColors.success : Colors.grey.shade300,
      ),
    );
  }

  /// STEP 1: Date & Time Selection
  Widget _buildStep1DateTimeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pilih Tanggal & Waktu',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tentukan kapan Anda membutuhkan ruangan',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // User Selector (Admin only)
          if (_isAdmin) ...[
            _buildUserSelectorCard(),
            const SizedBox(height: 16),
          ],

          // Date Selector
          _buildDateSelectorCard(),
          const SizedBox(height: 16),

          // Time Range
          Row(
            children: [
              Expanded(child: _buildStartTimeCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildEndTimeCard()),
            ],
          ),

          // Duration Info
          if (_startTime != null && _endTime != null) ...[
            const SizedBox(height: 16),
            _buildDurationInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserSelectorCard() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _showUserSelector,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservasi untuk',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedUser?.name ?? 'Pilih Karyawan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _selectedUser != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedUser != null
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelectorCard() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDate != null
                          ? DateFormatter.longDate(_selectedDate!)
                          : 'Pilih Tanggal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedDate != null
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartTimeCard() {
    final isEnabled = _selectedDate != null;

    return Card(
      elevation: 2,
      color: isEnabled ? null : Colors.grey.shade100,
      child: InkWell(
        onTap: isEnabled ? _selectStartTime : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: isEnabled ? AppColors.primary : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mulai',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _startTime != null ? _formatTime(_startTime!) : '--:--',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _startTime != null && isEnabled
                      ? Colors.black87
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndTimeCard() {
    final isEnabled = _selectedDate != null && _startTime != null;

    return Card(
      elevation: 2,
      color: isEnabled ? null : Colors.grey.shade100,
      child: InkWell(
        onTap: isEnabled ? _selectEndTime : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: isEnabled ? AppColors.primary : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selesai',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _endTime != null ? _formatTime(_endTime!) : '--:--',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _endTime != null && isEnabled
                      ? Colors.black87
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationInfo() {
    final duration = _calculateDuration();
    if (duration == null) return const SizedBox.shrink();

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: AppColors.info, size: 20),
          const SizedBox(width: 8),
          Text(
            'Durasi: ${hours > 0 ? '$hours jam' : ''} ${minutes > 0 ? '$minutes menit' : ''}',
            style: TextStyle(
              color: AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// STEP 2: Room Selection
  Widget _buildStep2RoomSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Ruangan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ruangan tersedia untuk waktu yang dipilih',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedRoom == null
              ? _buildRoomSelectorPlaceholder()
              : _buildSelectedRoomCard(),
        ),
      ],
    );
  }

  Widget _buildRoomSelectorPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada ruangan dipilih',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketuk tombol di bawah untuk memilih',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showRoomSelector,
            icon: const Icon(Icons.add),
            label: const Text('Pilih Ruangan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRoomCard() {
    final room = _selectedRoom!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Room Image
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: room.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
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

                // Room Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name ?? 'Ruangan',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            room.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Kapasitas: ${room.capacity ?? 0} orang',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (room.description != null &&
                          room.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          room.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (room.facilities != null &&
                          room.facilities!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: room.facilities!
                              .map(
                                (f) => Chip(
                                  label: Text(
                                    f.name,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
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
          const SizedBox(height: 16),
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
    return Center(
      child: Icon(Icons.meeting_room, size: 48, color: Colors.grey.shade400),
    );
  }

  /// STEP 3: Details (Purpose & Visitor Count)
  Widget _buildStep3Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Detail Reservasi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Lengkapi informasi reservasi Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Purpose Field
          TextField(
            controller: _purposeController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Tujuan/Agenda Rapat',
              hintText: 'Contoh: Rapat koordinasi tim marketing Q2 2026',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.description),
              helperText: 'Jelaskan tujuan penggunaan ruangan',
            ),
          ),
          const SizedBox(height: 24),

          // Visitor Count
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Jumlah Peserta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filled(
                        onPressed: _visitorCount > 1
                            ? () {
                                setState(() {
                                  _visitorCount--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '$_visitorCount',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'orang',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filled(
                        onPressed: () {
                          final maxCapacity = _selectedRoom?.capacity ?? 100;
                          if (_visitorCount < maxCapacity) {
                            setState(() {
                              _visitorCount++;
                            });
                          } else {
                            AppSnackBar.show(
                              context,
                              'Kapasitas ruangan maksimal $maxCapacity orang',
                              type: SnackBarType.warning,
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedRoom?.capacity != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Kapasitas maksimal: ${_selectedRoom!.capacity} orang',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// STEP 4: Review & Confirmation
  Widget _buildStep4Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Review Reservasi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Periksa kembali detail reservasi Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Reservation Summary Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User (Admin only)
                  if (_isAdmin && _selectedUser != null) ...[
                    _buildReviewItem(
                      icon: Icons.person,
                      label: 'Reservasi untuk',
                      value: _selectedUser!.name,
                    ),
                    const Divider(height: 24),
                  ],

                  // Date & Time
                  _buildReviewItem(
                    icon: Icons.calendar_today,
                    label: 'Tanggal',
                    value: _selectedDate != null
                        ? DateFormatter.longDate(_selectedDate!)
                        : '-',
                  ),
                  const Divider(height: 24),
                  _buildReviewItem(
                    icon: Icons.access_time,
                    label: 'Waktu',
                    value: _startTime != null && _endTime != null
                        ? '${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}'
                        : '-',
                  ),
                  const Divider(height: 24),

                  // Room
                  _buildReviewItem(
                    icon: Icons.meeting_room,
                    label: 'Ruangan',
                    value: _selectedRoom?.name ?? '-',
                  ),
                  const Divider(height: 24),

                  // Visitor Count
                  _buildReviewItem(
                    icon: Icons.people,
                    label: 'Jumlah Peserta',
                    value: '$_visitorCount orang',
                  ),
                  const Divider(height: 24),

                  // Purpose
                  _buildReviewItem(
                    icon: Icons.description,
                    label: 'Tujuan',
                    value: _purposeController.text.isEmpty
                        ? '(Belum diisi)'
                        : _purposeController.text,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Warning Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reservasi Anda akan menunggu persetujuan admin sebelum dapat digunakan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning.withValues(alpha: 0.8),
                    ),
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
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Navigation Buttons
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _nextStep,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    // Validation per step
    if (!_validateCurrentStep()) {
      return;
    }

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
      case 0: // Date & Time
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

      case 1: // Room
        if (_selectedRoom == null) {
          AppSnackBar.show(
            context,
            'Silakan pilih ruangan',
            type: SnackBarType.error,
          );
          return false;
        }
        return true;

      case 2: // Details
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

      case 3: // Review
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reservationService.createReservation(
        roomId: _selectedRoom!.id!,
        startTime: _startDateTime!,
        endTime: _endDateTime!,
        purpose: _purposeController.text.trim(),
        visitorCount: _visitorCount,
        userId: _selectedUser?.id,
      );

      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Reservasi berhasil dibuat! Menunggu persetujuan admin.',
        type: SnackBarType.success,
      );

      // Kembali ke halaman sebelumnya dengan result true
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        'Gagal membuat reservasi: ${e.toString()}',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
        // Reset room selection if date changed
        if (_selectedRoom != null) {
          _selectedRoom = null;
        }
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
      builder: (_, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate: tidak boleh di masa lalu jika hari ini
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
        // Reset end time & room if start time changed
        if (_endTime != null && !_isTimeAfter(_endTime!, picked)) {
          _endTime = null;
        }
        if (_selectedRoom != null) {
          _selectedRoom = null;
        }
      });
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
      builder: (_, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate: end time must be after start time
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
        // Reset room if time changed
        if (_selectedRoom != null) {
          _selectedRoom = null;
        }
      });
    }
  }

  Future<void> _showUserSelector() async {
    final selectedUser = await UserSelectorSection.showBottomSheet(
      context: context,
      selectedUserId: _selectedUser?.id,
    );

    if (selectedUser != null) {
      setState(() {
        _selectedUser = selectedUser;
      });
    }
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

    if (selectedRoom != null) {
      setState(() {
        _selectedRoom = selectedRoom;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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
