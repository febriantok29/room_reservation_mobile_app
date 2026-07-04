import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/requests/room_request.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/pages/room/facility_selector_page.dart';
import 'package:rapa_track_mobile_app/app/services/room_service.dart';

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
        appBar: AppBar(
          title: Text(
            _isNewRoom
                ? 'Tambah Ruangan'
                : (widget.editable ? 'Edit Ruangan' : 'Detail Ruangan'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _buildFormSection(),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(title: 'Informasi Dasar'),
          _buildTextField(
            controller: _nameController,
            label: 'Nama Ruangan',
            validator: _validateRoomName,
          ),
          const SizedBox(height: 16),
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
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _floorController,
                  label: 'Lantai',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';

                    final floor = int.tryParse(v);

                    if (floor == null) return 'Harus angka';

                    if (floor < 1 || floor > 4) return 'Lantai 1-4';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Deskripsi',
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            title: 'Fasilitas',
            actionSection: widget.editable
                ? TextButton.icon(
                    onPressed: _openFacilitySelector,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Kelola'),
                  )
                : null,
          ),
          _buildFacilitiesSection(),
          const SizedBox(height: 24),

          if (widget.editable) ...[
            _buildSectionHeader(title: 'Status'),
            SwitchListTile(
              title: const Text('Sedang Maintenance'),
              subtitle: const Text('Ruangan tidak tersedia untuk reservasi'),
              value: _isMaintenance,
              onChanged: (val) => setState(() => _isMaintenance = val),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
          ] else if (_currentRoom?.isMaintenance ?? false) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ruangan sedang dalam maintenance',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (widget.editable)
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Simpan Ruangan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, Widget? actionSection}) {
    Widget section = Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );

    if (actionSection != null) {
      section = Row(
        children: [
          Expanded(child: section),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: actionSection,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: section,
    );
  }

  Widget _buildFacilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFacilities.isEmpty)
          const Text(
            'Tidak ada fasilitas dipilih',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedFacilities.map((facility) {
              return Chip(
                label: Text(facility.name),
                labelStyle: const TextStyle(fontSize: 12),
                avatar: facility.icon != null
                    ? Icon(facility.icon, size: 16, color: Colors.blue)
                    : null,
                backgroundColor: Colors.blue.shade50,
              );
            }).toList(),
          ),
      ],
    );
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: !widget.editable,
      validator: validator,
    );
  }

  String? _validateRoomName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama ruangan tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  Future<bool> _checkDuplicateName(String name) async {
    try {
      final rooms = await _service.getRoomList();

      final lowerName = name.toLowerCase().trim();

      return rooms.any((room) {
        final isSameName = room.name?.toLowerCase() == lowerName;
        final isNotCurrentRoom = room.id != _currentRoom?.id;
        return isSameName && isNotCurrentRoom;
      });
    } catch (_) {
      return false;
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
          title: 'Nama Sudah Ada',
          message:
              'Nama ruangan "$name" sudah digunakan. Gunakan nama yang berbeda.',
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
          message: 'Berhasil $actionText',
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showStatusDialog(title: 'Error', message: 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showStatusDialog({
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
