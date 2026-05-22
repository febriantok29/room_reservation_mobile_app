import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/requests/room_request.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/models/room_facility.dart';
import 'package:room_reservation_mobile_app/app/pages/room/facility_selector_page.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

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
          _buildTextField(
            controller: _nameController,
            label: 'Nama Ruangan',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _capacityController,
                  label: 'Kapasitas',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (int.tryParse(v) == null) return 'Harus angka';
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
                    if (int.tryParse(v) == null) return 'Harus angka';
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
          _buildFacilitiesSection(),
          const SizedBox(height: 16),
          if (widget.editable)
            SwitchListTile(
              title: const Text('Sedang Maintenance'),
              value: _isMaintenance,
              onChanged: (val) => setState(() => _isMaintenance = val),
              contentPadding: EdgeInsets.zero,
            ),
          if (!widget.editable && (_currentRoom?.isMaintenance ?? false))
            const ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text(
                'Ruangan sedang dalam maintenance',
                style: TextStyle(color: Colors.orange),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 32),
          if (widget.editable)
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fasilitas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.editable)
              TextButton.icon(
                onPressed: _openFacilitySelector,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Kelola'),
              ),
          ],
        ),
        const SizedBox(height: 8),
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
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: !widget.editable,
      validator: validator,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final request = RoomRequest(
      name: _nameController.text.trim(),
      floor: int.tryParse(_floorController.text.trim()),
      capacity: int.tryParse(_capacityController.text.trim()),
      description: _descriptionController.text.trim(),
      isMaintenance: _isMaintenance,
      facilityIds: _selectedFacilities.map((f) => f.id).toList(),
    );

    final actionText = _currentRoom != null
        ? 'memperbarui ruangan'
        : 'menambahkan ruangan';

    try {
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
        _showStatusDialog(
          title: 'Error',
          message: 'Terjadi kesalahan saat $actionText: $e',
        );
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
