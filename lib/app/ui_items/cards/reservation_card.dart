import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/ui_items/reservation_status_badge.dart';

class ReservationCard extends StatefulWidget {
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
  State<ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<ReservationCard> {
  final _service = ReservationService();

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.reservation.status;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReservationDetail(
          reservation: widget.reservation,
          context: context,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.reservation.room?.name ?? "Tidak diketahui",
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

              _buildInfoRow(
                icon: Icons.access_time,
                text: widget.reservation.formattedRange,
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                icon: Icons.people,
                text: '${widget.reservation.visitorCount ?? 1} orang',
              ),
              if (widget.reservation.purpose != null &&
                  widget.reservation.purpose!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  icon: Icons.description,
                  text: widget.reservation.purpose!,
                  maxLines: 2,
                ),
              ],

              if (widget.user.isAdmin && widget.reservation.user != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  icon: Icons.person,
                  text: widget.reservation.user!.name,
                ),
              ],

              _buildActionButtons(currentStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReservationStatus status) {
    final buttons = <Widget>[];

    if (widget.user.isAdmin) {
      if (status.canBeApproved) {
        buttons.add(
          _buildActionButton(
            label: 'Setujui',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                title: 'Setujui Reservasi',
                content:
                    'Apakah Anda yakin ingin menyetujui reservasi ruangan ini?',
              );

              if (confirm && mounted) {
                _performAction(
                  context: context,
                  action: () =>
                      _service.approveReservation(widget.reservation.id!),
                  loadingText: 'Menyetujui reservasi...',
                  successText: 'Reservasi berhasil disetujui',
                );
              }
            },
          ),
        );

        buttons.add(
          _buildActionButton(
            label: 'Tolak',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                title: 'Tolak Reservasi',
                content: 'Apakah Anda yakin ingin menolak reservasi ini?',
                isDestructive: true,
              );

              if (confirm && mounted) {
                _performAction(
                  context: context,
                  action: () =>
                      _service.rejectReservation(widget.reservation.id!),
                  loadingText: 'Menolak reservasi...',
                  successText: 'Reservasi berhasil ditolak',
                );
              }
            },
          ),
        );
      }

      if (status.canBeCompleted) {
        buttons.add(
          _buildActionButton(
            label: 'Selesaikan',
            icon: Icons.done_all,
            color: Colors.blue,
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                title: 'Selesaikan Reservasi',
                content: 'Tandai reservasi ini telah selesai digunakan?',
              );

              if (confirm && mounted) {
                _performAction(
                  context: context,
                  action: () =>
                      _service.completeReservation(widget.reservation.id!),
                  loadingText: 'Menyelesaikan reservasi...',
                  successText: 'Reservasi berhasil diselesaikan',
                );
              }
            },
          ),
        );
      }
    }

    bool shouldShowCancel = status.canBeCancelled;

    if (widget.user.isAdmin && status == ReservationStatus.pending) {
      shouldShowCancel = false;
    }

    if (shouldShowCancel) {
      buttons.add(
        _buildActionButton(
          label: 'Batalkan',
          icon: Icons.cancel_outlined,
          color: Colors.red.shade400,
          onPressed: () async {
            final confirm = await _showConfirmDialog(
              title: 'Batalkan Reservasi',
              content: 'Apakah Anda yakin ingin membatalkan pengajuan ini?',
              isDestructive: true,
            );

            if (confirm && mounted) {
              _performAction(
                context: context,
                action: () =>
                    _service.cancelReservation(widget.reservation.id!),
                loadingText: 'Membatalkan reservasi...',
                successText: 'Reservasi berhasil dibatalkan',
              );
            }
          },
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    final spacedButtons = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      spacedButtons.add(buttons[i]);
      if (i < buttons.length - 1) {
        spacedButtons.add(const SizedBox(width: 8));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(children: spacedButtons),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),

        label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),

          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    return result ?? false;
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

      widget.onRefresh?.call();
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
