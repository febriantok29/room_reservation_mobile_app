import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/create_reservation_wizard_page.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/ui_items/cards/reservation_card.dart';
import 'package:rapa_track_mobile_app/app/ui_items/reservation_status_badge.dart';

class ReservationListPage extends StatefulWidget {
  final Profile user;

  const ReservationListPage({super.key, required this.user});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _reservationService = ReservationService();

  ReservationStatus? _filterStatus;
  Future<List<Reservation>>? _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  void _loadReservations() {
    setState(() {
      _reservationsFuture = _fetchReservations();
    });
  }

  Future<List<Reservation>> _fetchReservations() async {
    final result = await _reservationService.getReservationList(
      status: _filterStatus?.name,
    );

    return result.reservations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.isAdmin ? 'Semua Reservasi' : 'Reservasi Saya'),
        actions: [
          PopupMenuButton<ReservationStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Status',
            onSelected: (status) {
              _filterStatus = status;
              _loadReservations();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: null,
                onTap: () {
                  _filterStatus = null;
                  _loadReservations();
                },
                child: Row(
                  children: [
                    Icon(
                      _filterStatus == null
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Semua Status'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              _buildFilterMenuItem(ReservationStatus.pending),
              _buildFilterMenuItem(ReservationStatus.approved),
              _buildFilterMenuItem(ReservationStatus.rejected),
              _buildFilterMenuItem(ReservationStatus.completed),
              _buildFilterMenuItem(ReservationStatus.cancelled),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildAddButton(),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          _loadReservations();
          await _reservationsFuture;
        },
        child: FutureBuilder<List<Reservation>>(
          future: _reservationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Terjadi Kesalahan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadReservations,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            final reservations = snapshot.data ?? [];

            if (reservations.isEmpty && _filterStatus == null) {
              return _buildEmptyState(
                icon: Icons.event_busy,
                title: 'Belum Ada Reservasi',
                message: widget.user.isAdmin
                    ? 'Belum ada reservasi yang dibuat oleh pengguna'
                    : 'Anda belum memiliki reservasi.\nBuat reservasi pertama Anda!',
              );
            }

            if (reservations.isEmpty) {
              return _buildEmptyState(
                icon: Icons.filter_list_off,
                title: 'Tidak Ada Hasil',
                message:
                    'Tidak ada reservasi dengan status ${_filterStatus?.displayName ?? ""}',
                showClearFilter: true,
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: reservations.length,
              padding: const EdgeInsets.only(top: 8),
              itemBuilder: (_, index) {
                final reservation = reservations[index];
                final isLast = index == reservations.length - 1;

                Widget card = _buildCard(reservation);

                if (isLast) {
                  card = Padding(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    child: card,
                  );
                }

                return card;
              },
            );
          },
        ),
      ),
    );
  }

  PopupMenuItem<ReservationStatus> _buildFilterMenuItem(
    ReservationStatus status,
  ) {
    return PopupMenuItem(
      value: status,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _filterStatus == status
                ? Icons.check_circle
                : Icons.circle_outlined,
            size: 20,
            color: status.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ReservationStatusChip(status: status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    bool showClearFilter = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (showClearFilter) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  _filterStatus = null;
                  _loadReservations();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Hapus Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Reservation reservation) {
    return ReservationCard(
      reservation: reservation,
      user: widget.user,
      onRefresh: _loadReservations,
    );
  }

  Widget? _buildAddButton() {
    return FloatingActionButton.extended(
      onPressed: _createReservation,
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Buat Reservasi',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _createReservation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateReservationWizardPage(currentUser: widget.user),
      ),
    );

    if (result == true) {
      _loadReservations();
    }
  }
}
