import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/meta_data_response.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/reservation_create_page.dart';
import 'package:room_reservation_mobile_app/app/repositories/reservation_repository.dart';

class ReservationListPage extends StatefulWidget {
  const ReservationListPage({super.key});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  final _repository = ReservationRepository();

  @override
  void initState() {
    super.initState();
    _repository.loadMoreReservations();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Reservasi')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReservationCreatePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _repository.refresh();
        },
        child:
            StreamBuilder<
              ({List<Reservation> reservations, MetaDataResponse metadata})
            >(
              stream: _repository.reservationsStream,
              builder: (_, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _repository.refresh,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                final reservations = data.reservations;
                final metadata = data.metadata;

                if (reservations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('Belum ada reservasi'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      reservations.length +
                      (metadata.hasNextPage == true ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == reservations.length) {
                      _repository.loadMoreReservations();
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final reservation = reservations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          reservation.room?.name ?? 'Unknown Room',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reservation.startTime != null)
                              Text('🕐 ${reservation.formattedRange}'),
                            if (reservation.purpose != null)
                              Text('📝 ${reservation.purpose}'),
                          ],
                        ),
                        trailing: _buildStatusChip(reservation.status),
                      ),
                    );
                  },
                );
              },
            ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    IconData icon;

    switch (status?.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status?.toUpperCase() ?? 'UNKNOWN',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
