import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/room_selector_bottom_sheet.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/user_selector_bottom_sheet.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';
import 'package:room_reservation_mobile_app/app/ui_items/date_time_field.dart';

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
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  int _visitorCount = 1;
  Room? _selectedRoom;
  Profile? _selectedUser;
  final _purposeController = TextEditingController();

  // Form state
  bool _isLoading = false;
  String _errorMessage = '';
  bool get _isEditMode => widget.initialReservation != null;
  bool get _isAdmin => widget.user.isAdmin;
  @override
  void initState() {
    super.initState();

    // Populate form if in edit mode
    if (_isEditMode) {
      _startDateTime = widget.initialReservation!.startTime;
      _endDateTime = widget.initialReservation!.endTime;
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
  } // Widget pemilihan waktu mulai dan selesai

  Widget _buildDateTimeSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateTimeField(
          label: 'Waktu Mulai',
          value: _startDateTime,
          onChanged: (dateTime) {
            setState(() {
              _startDateTime = dateTime;
            });
          },
          minDateTime: DateTime.now(),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 12.0),
        DateTimeField(
          label: 'Waktu Selesai',
          value: _endDateTime,
          onChanged: (dateTime) {
            setState(() {
              _endDateTime = dateTime;
            });
          },
          minDateTime: _startDateTime ?? DateTime.now(),
          enabled: !_isLoading && _startDateTime != null,
        ),
        const SizedBox(height: 16.0),
      ],
    );
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
}
