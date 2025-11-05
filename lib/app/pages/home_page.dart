import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/home_statistics.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/models/reservation_count.dart';
import 'package:room_reservation_mobile_app/app/pages/calendar/calendar_page.dart';
import 'package:room_reservation_mobile_app/app/pages/login_page.dart';
import 'package:room_reservation_mobile_app/app/pages/reservation/reservation_list_page.dart';
import 'package:room_reservation_mobile_app/app/pages/room/room_list_page.dart';
import 'package:room_reservation_mobile_app/app/services/reservation_service.dart';
import 'package:room_reservation_mobile_app/app/services/room_service.dart';
import 'package:room_reservation_mobile_app/app/services/user_service.dart';
import 'package:room_reservation_mobile_app/app/states/auth_state.dart';
import 'package:room_reservation_mobile_app/app/utils/date_formatter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _now = DateTime.now();
  final _roomService = RoomService.getInstance();
  final _reservationService = ReservationService.getInstance();

  late Future<HomeStatistics> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _loadStatistics();
  }

  /// Load semua statistik yang diperlukan
  Future<HomeStatistics> _loadStatistics({bool forceRefresh = false}) async {
    final user = AuthState.currentUser;
    if (user?.reference == null) {
      return HomeStatistics.empty();
    }

    try {
      // Fetch data secara parallel
      final results = await Future.wait([
        _roomService.getAvailableRoomCount(forceRefresh: forceRefresh),
        _reservationService.getReservationCountByStatus(
          userId: user!.reference!,
        ),
      ]);

      final availableRooms = results[0] as int;
      final reservationCount = results[1] as ReservationCount;

      return HomeStatistics(
        availableRooms: availableRooms,
        activeReservations: reservationCount.active,
        pendingReservations: reservationCount.pending,
        completedReservations: reservationCount.completed,
      );
    } catch (e) {
      throw 'Gagal memuat statistik: ${e.toString()}';
    }
  }

  /// Handle pull to refresh
  Future<void> _onRefresh() async {
    setState(() {
      _statisticsFuture = _loadStatistics(forceRefresh: true);
    });
    await _statisticsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthState.currentUser;

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
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildUserHeader(user),
            const SizedBox(height: 24),
            _buildStatisticsSection(),
            const SizedBox(height: 24),
            _buildQuickActionsSection(user),
            const SizedBox(height: 24),
            // Tombol Generate Users (hanya untuk development/admin)
            if (user?.isAdmin == true) ...[
              ElevatedButton(
                onPressed: _generateUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Generate Users'),
              ),
            ],
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

  Widget _buildStatisticsSection() {
    return FutureBuilder<HomeStatistics>(
      future: _statisticsFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingStatistics();
        }

        if (snapshot.hasError) {
          return _buildErrorStatistics(snapshot.error.toString());
        }

        final stats = snapshot.data ?? HomeStatistics.empty();

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
                  value: '${stats.availableRooms}',
                  label: 'Ruang Tersedia',
                ),
                _buildStatCard(
                  icon: Icons.event_available,
                  iconColor: Colors.blue,
                  value: '${stats.activeReservations}',
                  label: 'Reservasi Aktif',
                ),
                _buildStatCard(
                  icon: Icons.pending_actions,
                  iconColor: Colors.orange,
                  value: '${stats.pendingReservations}',
                  label: 'Pending',
                ),
                _buildStatCard(
                  icon: Icons.calendar_today,
                  iconColor: Colors.purple,
                  value:
                      '${_now.day} ${DateFormatter.getMonthName(_now.month)}',
                  label: 'Hari Ini',
                ),
              ],
            ),
          ],
        );
      },
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
            const SizedBox(width: 12),
            Expanded(
              child: Container(), // Placeholder untuk simetri
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

  void _generateUsers() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm User Generation'),
        content: const Text('Are you sure you want to generate sample users?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    confirm ??= false;

    if (!confirm || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating users...'),
          ],
        ),
      ),
    );

    try {
      await UserService.generateSampleUsers();

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample users generated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating users: $e')));
    }
  }

  Future<void> _doLogout() async {
    await AuthState.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
