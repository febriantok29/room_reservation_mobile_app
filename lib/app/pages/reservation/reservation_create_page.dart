import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/api_response.dart';
import 'package:room_reservation_mobile_app/app/models/request/reservation_create_request.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';

class ReservationCreatePage extends StatefulWidget {
  const ReservationCreatePage({super.key});

  @override
  State<ReservationCreatePage> createState() => _ReservationCreatePageState();
}

class _ReservationCreatePageState extends State<ReservationCreatePage> {
  final _service = ReservationService.getInstance();
  final _formKey = GlobalKey<FormState>();

  final _now = DateTime.now();
  late DateTime _startDate = DateTime(
    _now.year,
    _now.month,
    _now.day,
    _now.hour + 1,
  );
  late DateTime _endDate = _startDate.add(const Duration(hours: 1));

  final _roomService = RoomService.getInstance();
  late Future<ApiResponse<List<Room>>> _availableRooms;
  final _request = ReservationCreateRequest();

  void _updateAvailableRooms() {
    setState(() {
      _availableRooms = _roomService.getRawAvailableRoom(
        start: _startDate,
        end: _endDate,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _updateAvailableRooms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      currentDate: _startDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
          _startDate.hour,
          _startDate.minute,
        );
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          _endDate.hour,
          _endDate.minute,
        );
      });
      _updateAvailableRooms();
    }
  }

  Future<void> _selectTimeRange() async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
    );

    if (startTime != null) {
      if (!mounted) {
        return;
      }

      final endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate),
      );

      if (endTime != null) {
        setState(() {
          _startDate = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            startTime.hour,
            startTime.minute,
          );
          _endDate = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            endTime.hour,
            endTime.minute,
          );
        });
        _updateAvailableRooms();
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final service = await _service;
      await service.createReservation(reservationForm: _request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mengajukan reservasi')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Ruangan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: ListTile(
                title: const Text('Tanggal'),
                subtitle: Text(
                  '${_startDate.toLocal().toString().split(' ')[0]} - ${_endDate.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateRange,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Waktu'),
                subtitle: Text(
                  '${TimeOfDay.fromDateTime(_startDate).format(context)} - ${TimeOfDay.fromDateTime(_endDate).format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectTimeRange,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<ApiResponse<List<Room>>>(
              future: _availableRooms,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final rooms = snapshot.data!.data ?? [];

                if (rooms.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Tidak ada ruangan yang tersedia'),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Ruangan',
                        border: OutlineInputBorder(),
                      ),
                      items: rooms.map((room) {
                        return DropdownMenuItem(
                          value: room.id,
                          child: Text(room.name ?? 'Unknown Room'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _request.roomId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Silakan pilih ruangan';
                        }
                        return null;
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tujuan',
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: Meeting Project X',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan isi tujuan';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _request.purpose = value;
                    _request.startTime = _startDate;
                    _request.endTime = _endDate;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('Ajukan Reservasi'),
            ),
          ],
        ),
      ),
    );
  }
}
