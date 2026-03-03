import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/core/config/app_feature_flags.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/reservation_modal_bottom_sheet.dart';
import 'package:room_reservation_mobile_app/app/providers/reservation_providers.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';
import 'package:room_reservation_mobile_app/app/ui_items/reservation_status_badge.dart';
import 'package:room_reservation_mobile_app/app/ui_items/cards/reservation_card.dart';

class ReservationListPage extends ConsumerStatefulWidget {
  final Profile user;

  const ReservationListPage({super.key, required this.user});

  @override
  ConsumerState<ReservationListPage> createState() =>
      _ReservationListPageState();
}

class _ReservationListPageState extends ConsumerState<ReservationListPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  final _service = ReservationService.getInstance();
  ReservationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
  }

  void _loadReservations() {
    setState(() {});
  }

  List<Reservation> _applyFilter(List<Reservation> reservations) {
    if (AppFeatureFlags.useApi) {
      return reservations;
    }

    if (_filterStatus == null) return reservations;
    return reservations
        .where((r) => r.getComputedStatus() == _filterStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.isAdmin ? 'Semua Reservasi' : 'Reservasi Saya'),
        actions: [
          // Filter button
          PopupMenuButton<ReservationStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Status',
            onSelected: (status) {
              setState(() => _filterStatus = status);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
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
              _buildFilterMenuItem(ReservationStatus.confirmed),
              _buildFilterMenuItem(ReservationStatus.upcoming),
              _buildFilterMenuItem(ReservationStatus.ongoing),
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
          ref.invalidate(
            reservationListByQueryProvider(
              ReservationListQuery(user: widget.user, status: _filterStatus),
            ),
          );
        },
        child: Consumer(
          builder: (context, ref, _) {
            final reservationState = ref.watch(
              reservationListByQueryProvider(
                ReservationListQuery(user: widget.user, status: _filterStatus),
              ),
            );

            return reservationState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
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
                        'Error: $error',
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
              },
              data: (allReservations) {
                final reservations = _applyFilter(allReservations);

                if (allReservations.isEmpty) {
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
        children: [
          Icon(
            _filterStatus == status
                ? Icons.check_circle
                : Icons.circle_outlined,
            size: 20,
            color: status.color,
          ),
          const SizedBox(width: 12),
          ReservationStatusChip(status: status),
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
                  setState(() => _filterStatus = null);
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
    // Update status if needed

    return ReservationCard(
      reservation: reservation,
      user: widget.user,
      service: _service,
      readOnly: AppFeatureFlags.useApi,
      onDeleteCompleted: _loadReservations,
    );
  }

  Widget? _buildAddButton() {
    if (AppFeatureFlags.useApi) {
      return null;
    }

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
