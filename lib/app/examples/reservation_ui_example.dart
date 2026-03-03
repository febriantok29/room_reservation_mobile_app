import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';
import 'package:room_reservation_mobile_app/app/ui_items/reservation_action_buttons.dart';
import 'package:room_reservation_mobile_app/app/ui_items/reservation_status_badge.dart';

/// Example implementation untuk menampilkan reservasi dengan status system baru
///
/// Fitur:
/// - Auto-update status berdasarkan waktu
/// - Status badge dengan warna
/// - Action buttons berdasarkan status & permission
/// - Cancel, Reschedule, Extend functionality
class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final VoidCallback? onRefresh;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.isAdmin = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Room name + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation.room?.name ?? 'Ruangan tidak tersedia',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ReservationStatusChip(status: reservation.status),
              ],
            ),
            const SizedBox(height: 12),

            // Reservation details
            _InfoRow(
              icon: Icons.access_time,
              label: 'Waktu',
              value: reservation.formattedRange,
            ),
            _InfoRow(
              icon: Icons.people,
              label: 'Jumlah',
              value: '${reservation.visitorCount ?? 0} orang',
            ),
            _InfoRow(
              icon: Icons.description,
              label: 'Tujuan',
              value: reservation.purpose ?? '-',
            ),

            // Show modification flags
            if (reservation.wasRescheduled || reservation.wasExtended) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (reservation.wasRescheduled)
                    const Chip(
                      avatar: Icon(Icons.schedule, size: 16),
                      label: Text(
                        'Di-reschedule',
                        style: TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (reservation.wasExtended)
                    Chip(
                      avatar: const Icon(Icons.add_circle, size: 16),
                      label: Text(
                        'Diperpanjang (${reservation.originalEndTime != null ? TimeOfDay.fromDateTime(reservation.originalEndTime!).format(context) : "-"} → ${reservation.endTime != null ? TimeOfDay.fromDateTime(reservation.endTime!).format(context) : "-"})',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],

            // Show cancellation info if cancelled
            if (reservation.status == ReservationStatus.cancelled &&
                reservation.cancellationReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alasan Pembatalan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reservation.cancellationReason!,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Show admin notes if any
            if (reservation.adminNotes != null &&
                reservation.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.adminNotes!,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            ReservationActionButtons(
              reservation: reservation,
              isAdmin: isAdmin,
              onView: () => _showDetail(context),
              onCancel: reservation.status.canBeCancelled
                  ? () => _handleCancel(context)
                  : null,
              onReschedule: reservation.status.canBeRescheduled
                  ? () => _handleReschedule(context)
                  : null,
              onExtend: reservation.status.canBeExtended && isAdmin
                  ? () => _handleExtend(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Reservasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${reservation.id ?? "-"}'),
            const SizedBox(height: 8),
            ReservationStatusBadge(
              status: reservation.status,
              showDescription: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Timeline Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ReservationStatusTimeline(status: reservation.status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context) async {
    // Show confirmation dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => CancelReservationDialog(reservation: reservation),
    );

    if (reason == null) return; // User cancelled

    try {
      // Show loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Membatalkan reservasi...')));

      // Cancel reservation
      await Future.delayed(const Duration(seconds: 1)); // Simulate delay

      // Success
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservasi berhasil dibatalkan'),
          backgroundColor: Colors.green,
        ),
      );

      onRefresh?.call();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReschedule(BuildContext context) async {
    // Show reschedule dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          RescheduleReservationDialog(reservation: reservation),
    );

    if (result == null) return;

    final newStart = result['startTime'] as DateTime;
    final newEnd = result['endTime'] as DateTime;

    try {
      // Show loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reschedule reservasi...')));

      // Reschedule reservation (with CSP validation)
      final reservationService = ReservationService.getInstance();
      await reservationService.rescheduleReservation(
        reservation.id!,
        newStart,
        newEnd,
        'current_user_id', // TODO: Get from auth
      );

      // Success
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservasi berhasil di-reschedule'),
          backgroundColor: Colors.green,
        ),
      );

      onRefresh?.call();
    } catch (e) {
      if (!context.mounted) return;

      // Show error with alternatives (if CSP failed)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reschedule Gagal'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleExtend(BuildContext context) async {
    // Show extend dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExtendReservationDialog(reservation: reservation),
    );

    if (result == null) return;

    final newEnd = result['endTime'] as DateTime;
    final reason = result['reason'] as String;

    try {
      // Show loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memperpanjang reservasi...')),
      );

      // Extend reservation (with CSP validation for conflicts)
      final reservationService = ReservationService.getInstance();
      await reservationService.extendReservation(
        reservation.id!,
        newEnd,
        reason,
      );

      // Success
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservasi berhasil diperpanjang'),
          backgroundColor: Colors.green,
        ),
      );

      onRefresh?.call();
    } catch (e) {
      if (!context.mounted) return;

      // Show error (likely CSP conflict)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Perpanjangan Gagal'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Example: List page with filters
class ReservationListPageExample extends StatefulWidget {
  const ReservationListPageExample({super.key});

  @override
  State<ReservationListPageExample> createState() =>
      _ReservationListPageExampleState();
}

class _ReservationListPageExampleState
    extends State<ReservationListPageExample> {
  final _reservationService = ReservationService.getInstance();
  List<Reservation> _reservations = [];
  ReservationStatus? _filterStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);

    try {
      final reservations = await _reservationService.getReservationList();

      // Filter by status if selected
      final filtered = _filterStatus != null
          ? reservations.where((r) => r.status == _filterStatus).toList()
          : reservations;

      setState(() {
        _reservations = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservasi Saya'),
        actions: [
          // Filter button
          PopupMenuButton<ReservationStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() => _filterStatus = status);
              _loadReservations();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Semua Status')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: ReservationStatus.confirmed,
                child: Row(
                  children: [
                    ReservationStatusChip(status: ReservationStatus.confirmed),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ReservationStatus.upcoming,
                child: Row(
                  children: [
                    ReservationStatusChip(status: ReservationStatus.upcoming),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ReservationStatus.ongoing,
                child: Row(
                  children: [
                    ReservationStatusChip(status: ReservationStatus.ongoing),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ReservationStatus.completed,
                child: Row(
                  children: [
                    ReservationStatusChip(status: ReservationStatus.completed),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ReservationStatus.cancelled,
                child: Row(
                  children: [
                    ReservationStatusChip(status: ReservationStatus.cancelled),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
          ? const Center(child: Text('Belum ada reservasi'))
          : RefreshIndicator(
              onRefresh: _loadReservations,
              child: ListView.builder(
                itemCount: _reservations.length,
                itemBuilder: (context, index) {
                  return ReservationCard(
                    reservation: _reservations[index],
                    isAdmin: false, // TODO: Check from auth
                    onRefresh: _loadReservations,
                  );
                },
              ),
            ),
    );
  }
}
