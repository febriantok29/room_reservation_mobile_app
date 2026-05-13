import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_api_service.dart';
import 'package:room_reservation_mobile_app/app/ui_items/reservation_status_badge.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final Profile user;
  final VoidCallback? onRefresh;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.user,
    this.onRefresh,
  });
  @override
  Widget build(BuildContext context) {
    final currentStatus = reservation.status;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            _showReservationDetail(reservation: reservation, context: context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nama ruangan dan status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      reservation.room?.name ?? "Tidak diketahui",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ReservationStatusChip(status: currentStatus),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 12),

              // Detail Info
              _buildInfoRow(
                icon: Icons.access_time,
                text: reservation.formattedRange,
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                icon: Icons.people,
                text: '${reservation.visitorCount ?? 1} orang',
              ),
              if (reservation.purpose != null &&
                  reservation.purpose!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  icon: Icons.description,
                  text: reservation.purpose!,
                  maxLines: 2,
                ),
              ],

              // User info (for admin)
              if (user.isAdmin && reservation.user != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(icon: Icons.person, text: reservation.user!.name),
              ],

              // Action buttons
              _buildActionButtons(context, currentStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ReservationStatus status) {
    final actions = <Widget>[];

    // Admin actions
    if (user.isAdmin) {
      if (status.canBeApproved) {
        actions.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _performAction(
                context: context,
                action: () =>
                    ReservationApiService().approveReservation(reservation.id!),
                loadingText: 'Menyetujui reservasi...',
                successText: 'Reservasi berhasil disetujui',
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Setujui'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ),
        );
        actions.add(const SizedBox(width: 8));
        actions.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _performAction(
                context: context,
                action: () =>
                    ReservationApiService().rejectReservation(reservation.id!),
                loadingText: 'Menolak reservasi...',
                successText: 'Reservasi berhasil ditolak',
              ),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Tolak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        );
      }
      if (status.canBeCompleted) {
        actions.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _performAction(
                context: context,
                action: () => ReservationApiService().completeReservation(
                  reservation.id!,
                ),
                loadingText: 'Menyelesaikan reservasi...',
                successText: 'Reservasi berhasil diselesaikan',
              ),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Selesaikan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
        );
      }
    }

    // User can cancel their own pending/approved reservation
    if (status.canBeCancelled) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _performAction(
              context: context,
              action: () =>
                  ReservationApiService().cancelReservation(reservation.id!),
              loadingText: 'Membatalkan reservasi...',
              successText: 'Reservasi berhasil dibatalkan',
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Batalkan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.shade400),
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(children: actions),
    );
  }

  void _performAction({
    required BuildContext context,
    required Future<Reservation> Function() action,
    required String loadingText,
    required String successText,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loadingText),
          ],
        ),
      ),
    );

    try {
      await action();

      if (!context.mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successText), backgroundColor: Colors.green),
      );

      onRefresh?.call();
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReservationDetail({
    required BuildContext context,
    required Reservation reservation,
  }) {
    final currentStatus = reservation.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(currentStatus.icon, color: currentStatus.color),
            const SizedBox(width: 8),
            const Expanded(child: Text('Detail Reservasi')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ReservationStatusBadge(
                status: currentStatus,
                showDescription: true,
              ),
              const SizedBox(height: 16),

              const Text(
                'Timeline Status:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ReservationStatusTimeline(status: currentStatus),
              const SizedBox(height: 16),

              const Divider(),
              const SizedBox(height: 8),

              _buildDetailRow(
                'Ruangan',
                reservation.room?.name ?? "Tidak diketahui",
                Icons.meeting_room,
              ),
              _buildDetailRow(
                'Waktu',
                reservation.formattedRange,
                Icons.access_time,
              ),
              _buildDetailRow(
                'Tujuan',
                reservation.purpose ?? "-",
                Icons.description,
              ),
              if (reservation.visitorCount != null)
                _buildDetailRow(
                  'Jumlah Pengunjung',
                  '${reservation.visitorCount} orang',
                  Icons.people,
                ),
              if (reservation.user != null)
                _buildDetailRow(
                  'Pemohon',
                  reservation.user!.name,
                  Icons.person,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    int? maxLines,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
