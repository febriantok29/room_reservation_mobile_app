import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';
import 'package:room_reservation_mobile_app/app/ui_items/reservation_status_badge.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final Profile user;
  final ReservationService service;
  final bool readOnly;
  final Function()? onDeleteCompleted;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.user,
    required this.service,
    this.readOnly = false,
    this.onDeleteCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final currentStatus = reservation.getComputedStatus();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            _showReservationDetail(reservation: reservation, context: context),
        onLongPress: () {
          if (readOnly) {
            return;
          }

          // Long press untuk aksi cepat (cancel)
          if (currentStatus.canBeCancelled) {
            _cancelReservation(reservation: reservation, context: context);
          }
        },
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.room?.name ?? "Tidak diketahui",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reservation.id != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${reservation.id}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ReservationStatusChip(status: currentStatus),
                ],
              ),
              const SizedBox(height: 12),

              // Divider
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

              // Cancellation Reason (if cancelled)
              if (currentStatus == ReservationStatus.cancelled &&
                  reservation.cancellationReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alasan Pembatalan:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                  ),
                ),
              ],

              // Admin Notes
              if (reservation.adminNotes != null &&
                  reservation.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.blue.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan Admin:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reservation.adminNotes!,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Flag modifikasi
              if (reservation.wasRescheduled || reservation.wasExtended) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (reservation.wasRescheduled)
                      _buildModificationChip(
                        'Di-reschedule',
                        Icons.event_repeat,
                        Colors.orange,
                      ),
                    if (reservation.wasExtended)
                      _buildModificationChip(
                        'Diperpanjang',
                        Icons.timer,
                        Colors.blue,
                      ),
                  ],
                ),
              ],

              // Tombol aksi (jika status memungkinkan)
              if (!readOnly && currentStatus.canBeCancelled) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelReservation(
                      reservation: reservation,
                      context: context,
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Batalkan Reservasi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade400, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Menampilkan detail reservasi
  void _showReservationDetail({
    required BuildContext context,
    required Reservation reservation,
  }) {
    final currentStatus = reservation.getComputedStatus();

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
              // ID Reservasi
              if (reservation.id != null) ...[
                Text(
                  'ID: ${reservation.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Status Badge
              ReservationStatusBadge(
                status: currentStatus,
                showDescription: true,
              ),
              const SizedBox(height: 16),

              // Timeline Status
              const Text(
                'Timeline Status:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ReservationStatusTimeline(status: currentStatus),
              const SizedBox(height: 16),

              // Divider
              const Divider(),
              const SizedBox(height: 8),

              // Detail Info
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

              // Cancellation Info
              if (reservation.cancellationReason != null) ...[
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
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Alasan Pembatalan:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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

              // Admin Notes
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.blue.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan Admin:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reservation.adminNotes!,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Modification Flags
              if (reservation.wasRescheduled || reservation.wasExtended) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (reservation.wasRescheduled)
                      Chip(
                        avatar: Icon(
                          Icons.event_repeat,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        label: const Text(
                          'Di-reschedule',
                          style: TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.orange.shade50,
                        side: BorderSide(color: Colors.orange.shade200),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (reservation.wasExtended)
                      Chip(
                        avatar: Icon(
                          Icons.timer,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                        label: Text(
                          'Diperpanjang${reservation.originalEndTime != null ? " (${TimeOfDay.fromDateTime(reservation.originalEndTime!).format(context)} → ${reservation.endTime != null ? TimeOfDay.fromDateTime(reservation.endTime!).format(context) : "-"})" : ""}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide(color: Colors.blue.shade200),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
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

  // Batalkan reservasi dengan dialog input reason
  void _cancelReservation({
    required BuildContext context,
    required Reservation reservation,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Reservasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin membatalkan reservasi ini?'
              ' Tindakan ini tidak dapat dibatalkan.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan Pembatalan *',
                hintText: 'Masukkan alasan pembatalan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan pembatalan wajib diisi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop();

              try {
                final userId = user.id;

                if (userId == null) {
                  throw 'User ID tidak ditemukan';
                }

                // Tampilkan loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Membatalkan reservasi...'),
                      ],
                    ),
                  ),
                );

                // Batalkan reservasi dengan reason
                await service.cancelReservation(reservation.id!, reason, user);

                if (!context.mounted) return;

                // Tutup dialog loading
                Navigator.of(context).pop();

                if (onDeleteCompleted != null) {
                  onDeleteCompleted!();
                }

                // Tampilkan notifikasi sukses
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reservasi berhasil dibatalkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Tutup dialog loading jika masih terbuka
                if (context.mounted) Navigator.of(context).pop();

                // Tampilkan error
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal membatalkan reservasi: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.red),
            ),
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

  Widget _buildModificationChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
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
