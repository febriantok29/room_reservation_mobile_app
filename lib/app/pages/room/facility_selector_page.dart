import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/room_facility.dart';
import 'package:rapa_track_mobile_app/app/services/facility_service.dart';

class FacilitySelectorPage extends StatefulWidget {
  final List<RoomFacility> initialSelectedFacilities;

  const FacilitySelectorPage({
    super.key,
    required this.initialSelectedFacilities,
  });

  @override
  State<FacilitySelectorPage> createState() => _FacilitySelectorPageState();
}

class _FacilitySelectorPageState extends State<FacilitySelectorPage> {
  final _service = FacilityService();
  final _searchController = TextEditingController();

  late final _selectedFacilities = List<RoomFacility>.from(
    widget.initialSelectedFacilities,
  );
  late Future<List<RoomFacility>> _facilitiesFuture = _service
      .getFacilityList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _facilitiesFuture = _service.getFacilityList(search: val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pilih Fasilitas${_selectedFacilities.isNotEmpty ? ' (${_selectedFacilities.length})' : ''}',
        ),
        actions: [
          if (_selectedFacilities.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pop(_selectedFacilities),
              child: const Text(
                'Pilih',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari fasilitas...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<RoomFacility>>(
      future: _facilitiesFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Gagal memuat fasilitas: ${snapshot.error}'),
          );
        }

        final facilities = snapshot.data ?? [];

        if (facilities.isEmpty) {
          return const Center(child: Text('Fasilitas tidak ditemukan'));
        }

        return ListView.separated(
          itemCount: facilities.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) => _buildCard(facilities[index]),
        );
      },
    );
  }

  Widget _buildCard(RoomFacility facility) {
    final isSelected = _selectedFacilities.any((f) => f.id == facility.id);

    return CheckboxListTile(
      title: Text(facility.name),
      secondary: facility.icon != null
          ? Icon(facility.icon, color: Colors.blue)
          : const Icon(Icons.check_circle_outline),
      activeColor: Colors.blue,
      controlAffinity: ListTileControlAffinity.trailing,
      value: isSelected,
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            if (!isSelected) {
              _selectedFacilities.add(facility);
            }
          } else {
            _selectedFacilities.removeWhere((f) => f.id == facility.id);
          }
        });
      },
    );
  }
}
