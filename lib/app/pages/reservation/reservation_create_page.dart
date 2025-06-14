import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_reservation_mobile_app/app/models/request/reservation_create_request.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/pages/room_selector_page.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';

class ReservationCreatePage extends StatefulWidget {
  const ReservationCreatePage({super.key});

  @override
  State<ReservationCreatePage> createState() => _ReservationCreatePageState();
}

class _ReservationCreatePageState extends State<ReservationCreatePage> {
  final _service = ReservationService.getInstance();
  final _formKey = GlobalKey<FormState>();

  // Create datetime formater for "Jumat, 15 Sep 2023"
  final _dateFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

  final _now = DateTime.now();
  late DateTime _startDate = DateTime(
    _now.year,
    _now.month,
    _now.day,
    _now.hour + 1,
  );
  late DateTime _endDate = _startDate.add(const Duration(hours: 1));

  final _request = ReservationCreateRequest();

  // Selected room
  Room? _selectedRoom;

  // Method to navigate to room selector page
  Future<void> _selectRoom() async {
    final selectedRoom = await Navigator.push<Room>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RoomSelectorPage(startDate: _startDate, endDate: _endDate),
      ),
    );

    if (selectedRoom != null) {
      setState(() {
        _selectedRoom = selectedRoom;
        _request.roomId = selectedRoom.id;
      });
    }
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

        _request.startTime = _startDate;
        _request.endTime = _endDate;
      });
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

          _request.startTime = _startDate;
          _request.endTime = _endDate;
        });
      }
    }
  }

  Future<void> _submit() async {
    // Check if room is selected
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih ruangan terlebih dahulu')),
      );
      return;
    }

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
                  '${_dateFormatter.format(_startDate)} - ${_dateFormatter.format(_endDate)}',
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
            // Room selection card
            Card(
              child: ListTile(
                title: const Text('Ruangan'),
                subtitle: _selectedRoom != null
                    ? Text(_selectedRoom!.name ?? 'Unknown Room')
                    : const Text('Pilih ruangan'),
                trailing: const Icon(Icons.meeting_room),
                onTap: _selectRoom,
              ),
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
                    // Room ID is already set when room is selected
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
