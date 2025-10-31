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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showReservationDetail(reservation),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tanggal: ${reservation.formattedRange}',
                style: const TextStyle(fontSize: 14),
              ),
              if (reservation.purpose != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Tujuan: ${reservation.purpose}',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Tombol aksi jika status PENDING
              // if (reservation.status == Reservation.statusPending)
              //   Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       TextButton(
              //         onPressed: () => _editReservation(reservation),
              //         child: const Text('Edit'),
              //       ),
              //       TextButton(
              //         onPressed: () => _cancelReservation(reservation),
              //         child: const Text(
              //           'Batal',
              //           style: TextStyle(color: Colors.red),
              //         ),
              //       ),
              //     ],
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton(
      onPressed: _createReservation,
      child: const Icon(Icons.add),
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
