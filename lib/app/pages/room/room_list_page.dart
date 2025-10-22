import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

class RoomListPage extends StatefulWidget {
  final Profile user;

  const RoomListPage({super.key, required this.user});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final _roomService = RoomService.getInstance();
  late Future<List<Room>> _rooms;

  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    _rooms = _roomService.getRoomList(showAll: _showAll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Ruangan Meeting')),
      floatingActionButton: _addRoomButton(),
      body: Column(
        children: [
          if (widget.user.isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(child: Text('Lihat semua ruangan')),
                  Switch(
                    value: _showAll,
                    onChanged: (_) {
                      setState(() {
                        _showAll = !_showAll;
                        _loadRooms();
                      });
                    },
                  ),
                ],
              ),
            ),
          FutureBuilder<List<Room>>(
            future: _rooms,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data ?? [];

              if (data.isEmpty) {
                return const Center(child: Text('Tidak ada ruangan tersedia.'));
              }

              return Flexible(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (_, index) {
                    final room = data[index];

                    Widget card = _buildCard(room);

                    if (widget.user.isAdmin) {
                      card = Slidable(
                        key: ValueKey(room.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _showRoomBottomSheet(room),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (_) => _confirmDeleteRoom(room),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Hapus',
                            ),
                          ],
                        ),
                        child: card,
                      );
                    }

                    return card;
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan detail ruangan dalam bentuk kartu
  Widget _buildCard(Room room) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bagian gambar ruangan
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                ),
                child: Image.network(
                  room.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.meeting_room, size: 64),
                  ),
                ),
              ),
            ),
            // Bagian informasi ruangan
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama ruangan
                    Text(
                      room.name ?? '(Tanpa Nama)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Informasi ruangan dengan ikon
                    _buildRoomInfoRow(
                      icon: Icons.location_on,
                      value: room.location ?? '-',
                    ),
                    const SizedBox(height: 4),
                    _buildRoomInfoRow(
                      icon: Icons.people,
                      value: '${room.capacity ?? '-'} orang',
                    ),

                    // Deskripsi jika ada
                    if (room.description != null &&
                        room.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: _buildRoomInfoRow(
                          icon: Icons.description,
                          value: room.description ?? '',
                        ),
                      ),

                    // Status maintenance
                    if (room.isMaintenance == true)
                      _buildStatusTag(
                        Icons.build,
                        'DALAM PERAWATAN',
                        Colors.orange.shade800,
                      ),

                    // Status hapus untuk admin
                    if (room.deletedAt != null && widget.user.isAdmin)
                      _buildStatusTag(
                        Icons.delete,
                        'Dihapus pada ${room.deletedAtFormatted}',
                        Colors.red.shade800,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk menampilkan baris informasi ruangan dengan ikon
  Widget _buildRoomInfoRow({
    required IconData icon,
    required String value,
    String? label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black87),
              children: [
                if (label != null && label.isNotEmpty)
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Widget untuk menampilkan status khusus (maintenance, deleted)
  Widget _buildStatusTag(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _addRoomButton() {
    if (!widget.user.isAdmin) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () => _showRoomBottomSheet(),
      tooltip: 'Tambah Ruangan',
      child: const Icon(Icons.add),
    );
  }

  /// Menampilkan bottom sheet untuk tambah/edit ruangan
  void _showRoomBottomSheet([Room? room]) async {
    final isEditing = room != null;

    final nameController = TextEditingController(text: room?.name);
    final locationController = TextEditingController(text: room?.location);
    final capacityController = TextEditingController(
      text: room?.capacity?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: room?.description ?? '',
    );

    bool? needRefresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true, // Gunakan safe area
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        bool isMaintenance = room?.isMaintenance ?? false;
        bool isLoading = false;
        String errorMessage = '';

        return StatefulBuilder(
          builder: (_, setModalState) {
            // Hitung ukuran keyboard dan pastikan bottomSheet cukup tinggi
            final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 8.0,
                bottom: keyboardSpace > 0
                    ? keyboardSpace + 16.0
                    : 24.0, // Tambahkan extra padding jika keyboard muncul
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        isEditing
                            ? 'Edit Ruangan Meeting'
                            : 'Tambah Ruangan Meeting',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    if (errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Ruangan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.meeting_room),
                        ),
                        enabled: !isLoading,
                        textInputAction: TextInputAction.next,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        enabled: !isLoading,
                        textInputAction: TextInputAction.next,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Kapasitas',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !isLoading,
                        textInputAction: TextInputAction.next,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        enabled: !isLoading,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Sedang dalam perawatan')),
                          Switch(
                            value: isMaintenance,
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setModalState(() {
                                      isMaintenance = value;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                // Validasi input
                                if (nameController.text.trim().isEmpty) {
                                  setModalState(() {
                                    errorMessage =
                                        'Nama ruangan tidak boleh kosong';
                                  });
                                  return;
                                }

                                if (locationController.text.trim().isEmpty) {
                                  setModalState(() {
                                    errorMessage = 'Lokasi tidak boleh kosong';
                                  });
                                  return;
                                }

                                int? capacity;
                                if (capacityController.text.isNotEmpty) {
                                  try {
                                    capacity = int.parse(
                                      capacityController.text,
                                    );
                                    if (capacity <= 0) {
                                      setModalState(() {
                                        errorMessage =
                                            'Kapasitas harus lebih dari 0';
                                      });
                                      return;
                                    }
                                  } catch (e) {
                                    setModalState(() {
                                      errorMessage =
                                          'Kapasitas harus berupa angka';
                                    });
                                    return;
                                  }
                                }

                                setModalState(() {
                                  isLoading = true;
                                  errorMessage = '';
                                });

                                try {
                                  if (isEditing) {
                                    // Update objek Room yang sudah ada
                                    final updatedRoom = room.copyWith(
                                      name: nameController.text.trim(),
                                      location: locationController.text.trim(),
                                      capacity: capacity,
                                      description: descriptionController.text
                                          .trim(),
                                      isMaintenance: isMaintenance,
                                    );

                                    // Siapkan data untuk update
                                    updatedRoom.prepareForUpdate(
                                      widget.user.id,
                                    );

                                    // Update room di Firestore
                                    await _roomService.updateRoom(updatedRoom);
                                  } else {
                                    // Buat objek Room baru
                                    final newRoom = Room(
                                      name: nameController.text.trim(),
                                      location: locationController.text.trim(),
                                      capacity: capacity,
                                      description: descriptionController.text
                                          .trim(),
                                      isMaintenance:
                                          isMaintenance, // Pastikan nilai isMaintenance benar
                                    );

                                    // Siapkan data untuk Firestore dengan user profile
                                    newRoom.prepareForCreate(widget.user.id);

                                    // Tambahkan room ke Firestore
                                    await _roomService.createRoom(newRoom);
                                  }

                                  // Tutup bottom sheet dan refresh
                                  if (!mounted) {
                                    return;
                                  }

                                  Navigator.pop(context, true);
                                } catch (e) {
                                  setModalState(() {
                                    isLoading = false;
                                    errorMessage =
                                        'Gagal menyimpan ruangan: ${e.toString()}';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
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
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Refresh daftar ruangan jika berhasil menambahkan/mengubah ruangan
    if (needRefresh == true) {
      setState(() {
        _loadRooms(); // Reload room data
      });
    }
  }

  /// Menampilkan konfirmasi sebelum menghapus ruangan
  void _confirmDeleteRoom(Room room) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ruangan "${room.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Hapus ruangan (soft delete)
        await _roomService.deleteRoom(room, widget.user.id!);

        // Reload daftar ruangan
        setState(() {
          _loadRooms();
        });

        if (!mounted) {
          return;
        }

        // Tampilkan snackbar

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ruangan ${room.name} berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus ruangan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
