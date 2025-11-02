import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

class RoomSelectorSection extends StatefulWidget {
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? selectedRoomId;

  const RoomSelectorSection({
    super.key,
    this.startDateTime,
    this.endDateTime,
    this.selectedRoomId,
  });

  @override
  State<RoomSelectorSection> createState() => _RoomSelectorSectionState();

  /// Menampilkan bottom sheet untuk memilih ruangan
  static Future<Room?> showBottomSheet({
    required BuildContext context,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? selectedRoomId,
  }) {
    return showModalBottomSheet<Room>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RoomSelectorSection(
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        selectedRoomId: selectedRoomId,
      ),
    );
  }

  static Future<Room?> showPage({
    required BuildContext context,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? selectedRoomId,
  }) {
    return Navigator.of(context).push<Room>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Pilih Ruangan')),
          body: RoomSelectorSection(
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            selectedRoomId: selectedRoomId,
          ),
        ),
      ),
    );
  }
}

class _RoomSelectorSectionState extends State<RoomSelectorSection> {
  final _roomService = RoomService.getInstance();

  String _searchKeyword = '';
  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  /// Load daftar ruangan yang tersedia
  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Jika waktu tidak ditentukan, tampilkan semua ruangan
      if (widget.startDateTime == null || widget.endDateTime == null) {
        final rooms = await _roomService.getRoomList(
          searchKeyword: _searchKeyword,
          showMaintenance: false,
        );

        setState(() {
          _rooms = rooms.where((room) => !room.isMaintenance!).toList();
        });
      } else {
        // Jika waktu ditentukan, filter ruangan yang available pada waktu tersebut
        // Gunakan API untuk mendapatkan ruangan yang tersedia
        final availableRooms = await _roomService.getAvailableRoom(
          start: widget.startDateTime!,
          end: widget.endDateTime!,
        );

        if (availableRooms.isEmpty) {
          setState(() {
            _errorMessage = 'Tidak dapat memuat ruangan yang tersedia';
          });

          return;
        }

        // Filter dengan keyword jika ada
        if (_searchKeyword.isNotEmpty) {
          final keyword = _searchKeyword.toLowerCase();

          setState(() {
            _rooms = availableRooms.where((room) {
              final name = room.name?.toLowerCase() ?? '';
              final location = room.location?.toLowerCase() ?? '';
              return name.contains(keyword) || location.contains(keyword);
            }).toList();
          });
        } else {
          setState(() {
            _rooms = availableRooms;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(),
          Expanded(child: _buildRoomList()),
        ],
      ),
    );
  }

  /// Widget search field
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari ruangan...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        onChanged: (value) {
          setState(() {
            _searchKeyword = value;
          });

          _loadRooms();
        },
      ),
    );
  }

  /// Widget daftar ruangan
  Widget _buildRoomList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_rooms.isEmpty) {
      return const Center(child: Text('Tidak ada ruangan tersedia'));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final isSelected = room.id == widget.selectedRoomId;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          color: isSelected ? Colors.blue.shade50 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(room);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room.name ?? 'Ruangan',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    room.location ?? 'Lokasi tidak diketahui',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (room.capacity != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      'Kapasitas: ${room.capacity} orang',
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
