import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/reservation_modal_bottom_sheet.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';

class ReservationListPage extends StatefulWidget {
  final Profile user;

  const ReservationListPage({super.key, required this.user});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  final _service = ReservationService.getInstance();
  late Future<List<Reservation>> _reservations;

  @override
  void initState() {
    _loadReservations();
    super.initState();
  }

  void _loadReservations() {
    setState(() {
      _reservations = _service.getReservationList(
        userId: widget.user.isAdmin ? null : widget.user.reference,
      );
    });
  }

  // Menampilkan detail reservasi
  void _showReservationDetail(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Reservasi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ruangan: ${reservation.room?.name ?? "Tidak diketahui"}'),
              const SizedBox(height: 8),
              Text('Tanggal: ${reservation.formattedRange}'),
              const SizedBox(height: 8),
              Text('Tujuan: ${reservation.purpose ?? "-"}'),
              if (reservation.visitorCount != null) ...[
                const SizedBox(height: 8),
                Text('Jumlah Pengunjung: ${reservation.visitorCount} orang'),
              ],
              if (reservation.approvedBy != null) ...[
                const SizedBox(height: 8),
                Text('Disetujui oleh: ${reservation.approvedBy}'),
              ],
              if (reservation.approvalNote != null) ...[
                const SizedBox(height: 8),
                Text('Catatan: ${reservation.approvalNote}'),
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

  // Edit reservasi
  void _editReservation(Reservation reservation) async {
    final bool? needRefresh = await ReservationModalBottomSheet.show(
      context: context,
      user: widget.user,
      reservation: reservation,
      onSuccess: _loadReservations,
    );

    if (needRefresh == true) {
      _loadReservations();
    }
  }

  // Batalkan reservasi
  void _cancelReservation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Reservasi'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan reservasi ini?'
          ' Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                final userId = widget.user.id;
                if (userId == null) {
                  throw Exception('User ID tidak ditemukan');
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

                // Batalkan reservasi
                await _service.cancelReservation(reservation.id!, userId);

                if (!mounted) return;

                // Tutup dialog loading
                if (mounted) Navigator.of(context).pop();

                // Refresh data
                _loadReservations();

                // Tampilkan notifikasi sukses
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reservasi berhasil dibatalkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Tutup dialog loading jika masih terbuka
                if (mounted) Navigator.of(context).pop();

                // Tampilkan error
                if (mounted) {
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
            child: const Text('Ya', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Reservasi')),
      floatingActionButton: _buildAddButton(),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _loadReservations();
        },
        child: FutureBuilder<List<Reservation>>(
          future: _reservations,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final reservations = snapshot.data ?? [];

            if (reservations.isEmpty) {
              return const Center(
                child: Text('Tidak ada reservasi ditemukan.'),
              );
            }

            return ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (_, index) {
                final reservation = reservations[index];

                return _buildCard(reservation);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(Reservation reservation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showReservationDetail(reservation),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama ruangan dan status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    reservation.room?.name ?? "Tidak diketahui",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(reservation.status),
              ],
            ),
            const SizedBox(height: 8),

            // Tanggal dan waktu dengan icon
            _buildInfoRow(
              icon: Icons.calendar_today,
              text: reservation.formattedRange,
            ),

            const SizedBox(height: 4),

            _buildInfoRow(
              icon: Icons.people,
              text: '${reservation.visitorCount ?? 1} orang',
            ),

            const SizedBox(height: 4),

            // Tujuan dengan icon
            if (reservation.purpose != null && reservation.purpose!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.edit_note,
                text: reservation.purpose!,
                maxLines: 2,
              ),
          ],
        ),
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

  Widget _buildStatusBadge(String? status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'PENDING':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'PENDING';
        break;
      case 'APPROVED':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'APPROVED';
        break;
      case 'REJECTED':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'REJECTED';
        break;
      case 'CANCELLED':
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = 'CANCELLED';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = status ?? 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton(
      onPressed: _createReservation,
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _createReservation() async {
    // Tampilkan modal bottom sheet untuk membuat reservasi baru
    final bool? needRefresh = await ReservationModalBottomSheet.show(
      context: context,
      user: widget.user,
      onSuccess: _loadReservations,
    );

    // Jika perlu refresh list reservasi
    if (needRefresh == true) {
      _loadReservations();
    }
  }
}
