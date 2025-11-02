import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/room_selector_bottom_sheet.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/user_selector_bottom_sheet.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';

class ReservationModalBottomSheet extends StatefulWidget {
  final Profile user;
  final Function? onSuccess;
  final Reservation? initialReservation; // Untuk edit mode

  const ReservationModalBottomSheet({
    super.key,
    required this.user,
    this.onSuccess,
    this.initialReservation,
  });

  @override
  State<ReservationModalBottomSheet> createState() =>
      _ReservationModalBottomSheetState();

  /// Menampilkan modal bottom sheet untuk membuat/edit reservasi
  static Future<bool?> show({
    required BuildContext context,
    required Profile user,
    Reservation? reservation,
    Function? onSuccess,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReservationModalBottomSheet(
        user: user,
        initialReservation: reservation,
        onSuccess: onSuccess,
      ),
    );
  }
}

class _ReservationModalBottomSheetState
    extends State<ReservationModalBottomSheet> {
  final _reservationService = ReservationService.getInstance();

  // Form fields
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _visitorCount = 1;
  Room? _selectedRoom;
  Profile? _selectedUser;
  final _purposeController = TextEditingController();

  // Form state
  bool _isLoading = false;
  String _errorMessage = '';
  bool get _isEditMode => widget.initialReservation != null;
  bool get _isAdmin => widget.user.isAdmin;

  // Getter untuk DateTime lengkap
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

    // Populate form if in edit mode
    if (_isEditMode) {
      final startTime = widget.initialReservation!.startTime;
      final endTime = widget.initialReservation!.endTime;

      if (startTime != null) {
        _selectedDate = DateTime(
          startTime.year,
          startTime.month,
          startTime.day,
        );
        _startTime = TimeOfDay(hour: startTime.hour, minute: startTime.minute);
      }

      if (endTime != null) {
        _endTime = TimeOfDay(hour: endTime.hour, minute: endTime.minute);
      }

      _visitorCount = widget.initialReservation!.visitorCount ?? 1;
      _selectedRoom = widget.initialReservation!.room;
      _selectedUser = widget.initialReservation!.user;
      _purposeController.text = widget.initialReservation!.purpose ?? '';
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung ukuran keyboard untuk padding bottom
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final bottomPadding = keyboardSpace > 0
        ? keyboardSpace + 24.0
        : 24.0 + bottomSafeArea;

    return Container(
      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildErrorMessage(),
            // Tampilkan user selector hanya jika admin
            if (_isAdmin) _buildUserSelector(),
            _buildDateTimeSelectors(),
            _buildRoomSelector(),
            _buildVisitorCounter(),
            _buildPurposeField(),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // Widget header form
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _isEditMode ? 'Edit Reservasi' : 'Buat Reservasi Baru',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Widget pesan error (jika ada)
  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(_errorMessage, style: TextStyle(color: Colors.red.shade800)),
    );
  }

  // Widget pemilihan pengguna (hanya untuk admin)
  Widget _buildUserSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: _isLoading ? null : _showUserSelector,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.grey),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  _selectedUser != null
                      ? _selectedUser!.name
                      : 'Pilih Pengguna',
                  style: TextStyle(
                    color: _selectedUser != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pemilihan ruangan
  Widget _buildRoomSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: _isLoading ? null : _showRoomSelector,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.meeting_room, color: Colors.grey),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  _selectedRoom?.name ?? 'Pilih Ruangan',
                  style: TextStyle(
                    color: _selectedRoom != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pemilihan tanggal dan waktu
  Widget _buildDateTimeSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pemilihan Tanggal
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: _isLoading ? null : _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 15.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'Pilih Tanggal',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? Colors.black
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),

        // Pemilihan Waktu Mulai dan Selesai
        Row(
          children: [
            // Waktu Mulai
            Expanded(
              child: InkWell(
                onTap: _isLoading || _selectedDate == null
                    ? null
                    : _selectStartTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 15.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4.0),
                    color: _selectedDate == null
                        ? Colors.grey.shade100
                        : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Mulai',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _startTime != null
                                ? _formatTime(_startTime!)
                                : '--:--',
                            style: TextStyle(
                              color: _startTime != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Waktu Selesai
            Expanded(
              child: InkWell(
                onTap: _isLoading || _selectedDate == null || _startTime == null
                    ? null
                    : _selectEndTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 15.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4.0),
                    color: _selectedDate == null || _startTime == null
                        ? Colors.grey.shade100
                        : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Selesai',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _endTime != null ? _formatTime(_endTime!) : '--:--',
                            style: TextStyle(
                              color: _endTime != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  // Helper function untuk format tanggal
  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Helper function untuk format waktu
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Function untuk memilih tanggal
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

        // Reset waktu jika tanggal berubah
        if (_isEditMode == false) {
          _startTime = null;
          _endTime = null;

          _resetSelectedRoom();
        }
      });

      // Langsung buka dialog waktu mulai setelah memilih tanggal
      if (mounted) {
        await _selectStartTime();
      }
    }
  }

  // Function untuk memilih waktu mulai
  Future<void> _selectStartTime() async {
    final now = DateTime.now();

    TimeOfDay initialTime =
        _startTime ?? TimeOfDay(hour: now.hour + 1, minute: 0);

    final isToday =
        _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    TimeOfDay? picked = await showTimePicker(
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

    picked ??= initialTime;

    // Validasi: jika hari ini, waktu tidak boleh di masa lalu
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

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Waktu Tidak Valid'),
            content: const Text('Waktu mulai tidak boleh di masa lalu.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        _selectStartTime();

        return;
      }
    }

    setState(() {
      _startTime = picked;

      if (_endTime != null && _isTimeAfter(_endTime!, picked!) == false) {
        _endTime = null;
      }

      _resetSelectedRoom();
    });

    // Langsung buka dialog waktu selesai setelah memilih waktu mulai
    if (!mounted) {
      return;
    }

    _selectEndTime();
  }

  // Function untuk memilih waktu selesai
  Future<void> _selectEndTime() async {
    final now = DateTime.now();
    TimeOfDay initialTime = TimeOfDay(hour: now.hour + 2, minute: 0);

    if (_endTime != null) {
      initialTime = _endTime!;
    } else if (_startTime != null) {
      initialTime = TimeOfDay(
        hour: (_startTime!.hour + 1) % 24,
        minute: _startTime!.minute,
      );
    }

    TimeOfDay? picked = await showTimePicker(
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

    picked ??= initialTime;

    // Validasi: waktu selesai harus setelah waktu mulai
    if (_startTime != null && _isTimeAfter(picked, _startTime!) == false) {
      if (!mounted) {
        return;
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Waktu Tidak Valid'),
          content: const Text('Waktu selesai harus setelah waktu mulai.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      _selectEndTime();
    }

    setState(() {
      _endTime = picked;

      _resetSelectedRoom();
    });
  }

  // Helper untuk membandingkan waktu
  bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour > time2.hour) return true;
    if (time1.hour == time2.hour && time1.minute > time2.minute) return true;
    return false;
  }

  // Widget counter jumlah pengunjung
  Widget _buildVisitorCounter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jumlah Pengunjung'),
          const SizedBox(height: 8.0),
          Row(
            children: [
              IconButton(
                onPressed: _isLoading || _visitorCount <= 1
                    ? null
                    : () => setState(() => _visitorCount--),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$_visitorCount orang',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _visitorCount++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget field tujuan
  Widget _buildPurposeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextField(
        controller: _purposeController,
        decoration: const InputDecoration(
          labelText: 'Tujuan Reservasi',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.description),
        ),
        enabled: !_isLoading,
        maxLines: 3,
        textInputAction: TextInputAction.done,
      ),
    );
  }

  // Tombol submit
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(_isEditMode ? 'PERBARUI' : 'SIMPAN'),
      ),
    );
  }

  // Menampilkan selector pengguna
  void _showUserSelector() async {
    final user = await UserSelectorBottomSheet.show(
      context: context,
      selectedUserId: _selectedUser?.employeeId,
    );

    if (user != null) {
      setState(() {
        _selectedUser = user;
      });

      return;
    }

    if (widget.user.isAdmin) {
      setState(() {
        _selectedUser = widget.user;
      });
    }
  }

  // Menampilkan selector ruangan
  void _showRoomSelector() async {
    final startDateTime = _startDateTime;
    final endDateTime = _endDateTime;

    if (startDateTime == null || endDateTime == null) {
      setState(() {
        _errorMessage = 'Silakan pilih waktu mulai dan selesai terlebih dahulu';
      });

      return;
    }

    final room = await RoomSelectorBottomSheet.show(
      context: context,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      selectedRoomId: _selectedRoom?.id,
    );

    if (room != null) {
      setState(() {
        _selectedRoom = room;
      });
    }
  } // Handler untuk submit form

  void _handleSubmit() async {
    // Validasi form
    // Validasi user jika admin
    if (_isAdmin && _selectedUser == null) {
      setState(() {
        _errorMessage = 'Silakan pilih pengguna terlebih dahulu';
      });
      return;
    }

    if (_selectedRoom == null) {
      setState(() {
        _errorMessage = 'Silakan pilih ruangan terlebih dahulu';
      });
      return;
    }

    if (_startDateTime == null) {
      setState(() {
        _errorMessage = 'Silakan pilih waktu mulai terlebih dahulu';
      });
      return;
    }

    if (_endDateTime == null) {
      setState(() {
        _errorMessage = 'Silakan pilih waktu selesai terlebih dahulu';
      });
      return;
    }
    if (_purposeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Silakan isi tujuan reservasi';
      });
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Reservation reservation;

      if (_isEditMode) {
        // Edit mode - update existing reservation
        reservation = widget.initialReservation!.copyWith(
          startDateTime: _startDateTime,
          endDateTime: _endDateTime,
          visitorCount: _visitorCount,
          purpose: _purposeController.text.trim(),
        );

        // Persiapkan untuk update
        reservation.prepareForUpdate();

        // Update reservation
        await _reservationService.updateReservation(reservation);
      } else {
        // Create mode - create new reservation
        // Create user reference for selected user or current user
        final userRef = _isAdmin && _selectedUser != null
            ? FirebaseFirestore.instance
                  .collection(Profile.collectionName)
                  .doc(_selectedUser!.id)
            : FirebaseFirestore.instance
                  .collection(Profile.collectionName)
                  .doc(widget.user.id);

        // Create room reference
        final roomRef = FirebaseFirestore.instance
            .collection(Room.collectionName)
            .doc(_selectedRoom!.id);

        reservation = Reservation(
          userRef: userRef,
          roomRef: roomRef,
          startTime: _startDateTime,
          endTime: _endDateTime,
          visitorCount: _visitorCount,
          purpose: _purposeController.text.trim(),
        );

        // Persiapkan untuk create
        reservation.prepareForCreate();

        // Create reservation
        await _reservationService.createReservation(reservation);
      }

      // Close modal and refresh parent
      if (!mounted) return;

      // Panggil callback onSuccess jika disediakan
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }

      // Kembali ke halaman sebelumnya dengan status success
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal menyimpan reservasi: ${e.toString()}';
      });
    }
  }

  void _resetSelectedRoom() {
    if (_selectedRoom != null) {
      _selectedRoom = null;
    }
  }
}
