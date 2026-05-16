import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/room_facility.dart';
import 'package:room_reservation_mobile_app/app/services/facility_service.dart';

class FacilitySelectorPage extends StatefulWidget {
  final List<RoomFacility> initialSelectedIds;

  const FacilitySelectorPage({super.key, required this.initialSelectedIds});

  @override
  State<FacilitySelectorPage> createState() => _FacilitySelectorPageState();
}

class _FacilitySelectorPageState extends State<FacilitySelectorPage> {
  final _service = FacilityService();
  final _searchController = TextEditingController();

  late final _selectedFacilities = List<RoomFacility>.from(
    widget.initialSelectedIds,
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
      appBar: AppBar(title: const Text('Pilih Fasilitas')),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: _buildSaveButton(),
    );
  }

  FloatingActionButton? _buildSaveButton() {
    return _selectedFacilities.isEmpty
        ? null
        : FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).pop(_selectedFacilities),
            label: const Text('Simpan'),
            icon: const Icon(Icons.save),
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
          itemBuilder: (_, index) {
            final facility = facilities[index];

            final isLast = index == facilities.length - 1;

            Widget content = _buildCard(facility);

            if (isLast) {
              content = Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: content,
              );
            }

            return content;
          },
        );
      },
    );
  }

  Widget _buildCard(RoomFacility facility) {
    final isSelected = _selectedFacilities
        .where((f) => f.id == facility.id)
        .isNotEmpty;

    return CheckboxListTile(
      title: Text(facility.name),
      secondary: facility.icon != null
          ? Icon(facility.icon, color: Colors.blue)
          : const Icon(Icons.check_circle_outline),
      value: isSelected,
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            _selectedFacilities.add(facility);
          } else {
            _selectedFacilities.removeWhere((f) => f.id == facility.id);
          }
        });
      },
    );
  }
}
