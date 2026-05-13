import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/pages/calendar/calendar_page.dart';
import 'package:room_reservation_mobile_app/app/pages/login_page.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/reservation_list_page.dart';
import 'package:room_reservation_mobile_app/app/pages/room/room_list_page.dart';
import 'package:room_reservation_mobile_app/app/providers/auth_providers.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/providers/reservation_providers.dart';
import 'package:room_reservation_mobile_app/app/providers/room_providers.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Room Reservation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _doLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roomListByQueryProvider(const RoomListQuery()));
          ref.invalidate(
            reservationListByQueryProvider(ReservationListQuery(user: user!)),
          );
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildUserHeader(user),
            const SizedBox(height: 24),
            _buildStatisticsSection(user),
            const SizedBox(height: 24),
            _buildQuickActionsSection(user),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(Profile? user) {
    if (user == null) return const SizedBox.shrink();

    // Ambil inisial nama untuk avatar
    final nameParts = user.name.split(' ');
    final initial = nameParts.isNotEmpty ? nameParts[0][0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar dengan inisial
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Informasi user
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang,',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.employeeId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.employeeId!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          // Icon notifikasi
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementasi notifikasi
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(Profile? user) {
    if (user == null) return const SizedBox.shrink();

    final roomState = ref.watch(roomListByQueryProvider(const RoomListQuery()));
    final reservationState = ref.watch(
      reservationListByQueryProvider(ReservationListQuery(user: user)),
    );

    final isLoading = roomState.isLoading || reservationState.isLoading;
    final hasError = roomState.hasError || reservationState.hasError;

    if (isLoading) return _buildLoadingStatistics();

    if (hasError) {
      final error = roomState.error ?? reservationState.error;
      return _buildErrorStatistics('$error');
    }

    final rooms = roomState.valueOrNull ?? [];
    final reservations = reservationState.valueOrNull ?? [];

    final availableRooms = rooms.where((r) => r.isMaintenance != true).length;
    final activeReservations = reservations
        .where((r) => r.status.isActive)
        .length;
    final pendingReservations = reservations
        .where((r) => r.status == ReservationStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Cepat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              icon: Icons.meeting_room,
              iconColor: Colors.green,
              value: '$availableRooms',
              label: 'Ruang Tersedia',
            ),
            _buildStatCard(
              icon: Icons.event_available,
              iconColor: Colors.blue,
              value: '$activeReservations',
              label: 'Reservasi Aktif',
            ),
            _buildStatCard(
              icon: Icons.pending_actions,
              iconColor: Colors.orange,
              value: '$pendingReservations',
              label: 'Pending',
            ),
            _buildStatCard(
              icon: Icons.calendar_today,
              iconColor: Colors.purple,
              value: '${_now.day} ${DateFormatter.getMonthName(_now.month)}',
              label: 'Hari Ini',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Cepat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: List.generate(
            4,
            (index) => Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStatistics(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Cepat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(Profile? user) {
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                iconColor: Colors.blue,
                label: 'Buat Reservasi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReservationListPage(user: user),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.list_alt,
                iconColor: Colors.green,
                label: 'Daftar Ruangan',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RoomListPage(user: user)),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_month,
                iconColor: Colors.purple,
                label: 'Kalender',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CalendarPage(user: user)),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doLogout() async {
    await ref.read(authSessionProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
