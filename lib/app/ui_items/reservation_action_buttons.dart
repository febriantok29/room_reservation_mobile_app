import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';

/// Widget untuk menampilkan action buttons berdasarkan status reservasi
///
/// Buttons yang ditampilkan:
/// - CONFIRMED: Cancel, Reschedule
/// - UPCOMING: Cancel (urgent)
/// - ONGOING: Extend (admin only)
/// - COMPLETED/CANCELLED: No actions (view only)
class ReservationActionButtons extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onExtend;
  final VoidCallback? onView;

  const ReservationActionButtons({
    super.key,
    required this.reservation,
    this.isAdmin = false,
    this.onCancel,
    this.onReschedule,
    this.onExtend,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final status = reservation.status;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // View button (always available)
        if (onView != null)
          _ActionButton(
            label: 'Lihat Detail',
            icon: Icons.visibility,
            color: Colors.blue,
            onPressed: onView!,
          ),

        // Cancel button (CONFIRMED, UPCOMING)
        if (status.canBeCancelled && onCancel != null)
          _ActionButton(
            label: status == ReservationStatus.upcoming
                ? 'Batalkan (Urgent)'
                : 'Batalkan',
            icon: Icons.cancel,
            color: Colors.red,
            onPressed: onCancel!,
          ),

        // Reschedule button (CONFIRMED only)
        if (status.canBeRescheduled && onReschedule != null)
          _ActionButton(
            label: 'Reschedule',
            icon: Icons.schedule,
            color: Colors.orange,
            onPressed: onReschedule!,
          ),

        // Extend button (ONGOING, admin only)
        if (status.canBeExtended && isAdmin && onExtend != null)
          _ActionButton(
            label: 'Perpanjang',
            icon: Icons.add_circle_outline,
            color: Colors.green,
            onPressed: onExtend!,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

/// Dialog untuk cancel reservation
class CancelReservationDialog extends StatefulWidget {
  final Reservation reservation;

  const CancelReservationDialog({super.key, required this.reservation});

  @override
  State<CancelReservationDialog> createState() =>
      _CancelReservationDialogState();
}

class _CancelReservationDialogState extends State<CancelReservationDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red.shade700),
          const SizedBox(width: 8),
          const Text('Batalkan Reservasi'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda yakin ingin membatalkan reservasi ini?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Ruangan: ${widget.reservation.room?.name ?? "-"}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Waktu: ${widget.reservation.formattedRange}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Alasan Pembatalan *',
              hintText: 'Mengapa Anda membatalkan reservasi ini?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 8),
          Text(
            '* Wajib diisi',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Ya, Batalkan'),
        ),
      ],
    );
  }

  void _handleCancel() async {
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan pembatalan wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    // Simulate processing (atau bisa diganti dengan actual API call jika ada)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Return reason to caller
    Navigator.of(context).pop(reason);
  }
}

/// Dialog untuk reschedule reservation
class RescheduleReservationDialog extends StatefulWidget {
  final Reservation reservation;

  const RescheduleReservationDialog({super.key, required this.reservation});

  @override
  State<RescheduleReservationDialog> createState() =>
      _RescheduleReservationDialogState();
}

class _RescheduleReservationDialogState
    extends State<RescheduleReservationDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    if (widget.reservation.startTime != null) {
      _selectedDate = DateTime(
        widget.reservation.startTime!.year,
        widget.reservation.startTime!.month,
        widget.reservation.startTime!.day,
      );
      _selectedStartTime = TimeOfDay.fromDateTime(
        widget.reservation.startTime!,
      );
      _selectedEndTime = widget.reservation.endTime != null
          ? TimeOfDay.fromDateTime(widget.reservation.endTime!)
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.schedule, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Reschedule Reservasi'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih waktu baru untuk reservasi Anda',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Date picker
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Pilih Tanggal',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _pickDate,
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),

          // Start time picker
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(
              _selectedStartTime != null
                  ? 'Mulai: ${_selectedStartTime!.format(context)}'
                  : 'Pilih Waktu Mulai',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _pickStartTime,
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),

          // End time picker
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(
              _selectedEndTime != null
                  ? 'Selesai: ${_selectedEndTime!.format(context)}'
                  : 'Pilih Waktu Selesai',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _pickEndTime,
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _canSubmit() ? _handleReschedule : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reschedule'),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _selectedDate != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _selectedStartTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
  }

  void _handleReschedule() {
    if (!_canSubmit()) return;

    final newStart = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

    final newEnd = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    Navigator.of(context).pop({'startTime': newStart, 'endTime': newEnd});
  }
}

/// Dialog untuk extend reservation (admin only)
class ExtendReservationDialog extends StatefulWidget {
  final Reservation reservation;

  const ExtendReservationDialog({super.key, required this.reservation});

  @override
  State<ExtendReservationDialog> createState() =>
      _ExtendReservationDialogState();
}

class _ExtendReservationDialogState extends State<ExtendReservationDialog> {
  final _reasonController = TextEditingController();
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    // Initialize with current end time + 30 minutes
    if (widget.reservation.endTime != null) {
      final suggested = widget.reservation.endTime!.add(
        const Duration(minutes: 30),
      );
      _selectedEndTime = TimeOfDay.fromDateTime(suggested);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.green.shade700),
          const SizedBox(width: 8),
          const Text('Perpanjang Reservasi'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perpanjang waktu reservasi yang sedang berlangsung',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Waktu selesai saat ini: ${widget.reservation.endTime != null ? TimeOfDay.fromDateTime(widget.reservation.endTime!).format(context) : "-"}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(
              _selectedEndTime != null
                  ? 'Waktu selesai baru: ${_selectedEndTime!.format(context)}'
                  : 'Pilih Waktu Selesai Baru',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _pickEndTime,
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Alasan Perpanjangan *',
              hintText: 'Mengapa perlu diperpanjang?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _selectedEndTime != null ? _handleExtend : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Perpanjang'),
        ),
      ],
    );
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
  }

  void _handleExtend() {
    if (_selectedEndTime == null) return;

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan perpanjangan wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newEnd = DateTime(
      widget.reservation.endTime!.year,
      widget.reservation.endTime!.month,
      widget.reservation.endTime!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    Navigator.of(context).pop({'endTime': newEnd, 'reason': reason});
  }
}
