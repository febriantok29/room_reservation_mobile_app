import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

/// Widget untuk menampilkan bottom sheet penambahan/edit ruangan
class RoomListModalBottomSheet extends StatefulWidget {
  final Room? room;
  final Profile user;
  final void Function()? onSuccess;

  const RoomListModalBottomSheet({
    super.key,
    this.room,
    required this.user,
    this.onSuccess,
  });

  /// Factory method untuk menampilkan bottom sheet dalam konteks tertentu
  static Future<bool?> show({
    required BuildContext context,
    required Profile user,
    Room? room,
    void Function()? onSuccess,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RoomListModalBottomSheet(
        room: room,
        user: user,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<RoomListModalBottomSheet> createState() =>
      _RoomListModalBottomSheetState();
}

class _RoomListModalBottomSheetState extends State<RoomListModalBottomSheet> {
  final _roomService = RoomService.getInstance();

  // Controllers untuk form fields
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;

  // Status form
  bool _isMaintenance = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // Mode edit atau tambah baru
  bool get _isEditing => widget.room != null;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controllers dengan nilai awal jika ada
    _nameController = TextEditingController(text: widget.room?.name);
    _locationController = TextEditingController(text: widget.room?.location);
    _capacityController = TextEditingController(
      text: widget.room?.capacity?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.room?.description ?? '',
    );

    // Set status maintenance awal
    _isMaintenance = widget.room?.isMaintenance ?? false;
  }

  @override
  void dispose() {
    // Membersihkan controllers saat widget dihapus
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
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
            _buildNameField(),
            _buildLocationField(),
            _buildCapacityField(),
            _buildDescriptionField(),
            _buildMaintenanceSwitch(),
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
        _isEditing ? 'Edit Ruangan Meeting' : 'Tambah Ruangan Meeting',
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

  // Field nama ruangan
  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Nama Ruangan',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.meeting_room),
        ),
        enabled: !_isLoading,
        textInputAction: TextInputAction.next,
      ),
    );
  }

  // Field lokasi
  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _locationController,
        decoration: const InputDecoration(
          labelText: 'Lokasi',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.location_on),
        ),
        enabled: !_isLoading,
        textInputAction: TextInputAction.next,
      ),
    );
  }

  // Field kapasitas
  Widget _buildCapacityField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _capacityController,
        decoration: const InputDecoration(
          labelText: 'Kapasitas',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.people),
        ),
        keyboardType: TextInputType.number,
        enabled: !_isLoading,
        textInputAction: TextInputAction.next,
      ),
    );
  }

  // Field deskripsi
  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Deskripsi',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.description),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
        enabled: !_isLoading,
      ),
    );
  }

  // Switch maintenance mode
  Widget _buildMaintenanceSwitch() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.build, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                const Text('Sedang dalam perawatan'),
              ],
            ),
          ),
          Switch(
            value: _isMaintenance,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _isMaintenance = value;
                    });
                  },
          ),
        ],
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
            : const Text('SIMPAN'),
      ),
    );
  }

  // Handler untuk submit form
  void _handleSubmit() async {
    // Validasi nama
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Nama ruangan tidak boleh kosong';
      });
      return;
    }

    // Validasi lokasi
    if (_locationController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Lokasi tidak boleh kosong';
      });
      return;
    }

    // Validasi kapasitas
    int? capacity;
    if (_capacityController.text.isNotEmpty) {
      try {
        capacity = int.parse(_capacityController.text);
        if (capacity <= 0) {
          setState(() {
            _errorMessage = 'Kapasitas harus lebih dari 0';
          });
          return;
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Kapasitas harus berupa angka';
        });
        return;
      }
    }

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isEditing) {
        // Update ruangan yang sudah ada dengan copyWith
        final updatedRoom = widget.room!.copyWith(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          capacity: capacity,
          description: _descriptionController.text.trim(),
          isMaintenance: _isMaintenance,
        );

        // Siapkan data untuk update
        updatedRoom.prepareForUpdate(widget.user.id);

        // Update room di Firestore
        await _roomService.updateRoom(updatedRoom);
      } else {
        // Buat ruangan baru
        final newRoom = Room(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          capacity: capacity,
          description: _descriptionController.text.trim(),
          isMaintenance: _isMaintenance,
        );

        // Siapkan data untuk Firestore
        newRoom.prepareForCreate(widget.user.id);

        // Tambahkan room ke Firestore
        await _roomService.createRoom(newRoom);
      }

      // Tutup bottom sheet dan refresh
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
        _errorMessage = 'Gagal menyimpan ruangan: ${e.toString()}';
      });
    }
  }
}
