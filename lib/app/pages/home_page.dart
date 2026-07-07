import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/pages/calendar/calendar_page.dart';
import 'package:rapa_track_mobile_app/app/pages/complaint/complaint_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/login_page.dart';
import 'package:rapa_track_mobile_app/app/pages/notification/notification_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/create_reservation_wizard_page.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/reservation_list_page.dart';
import 'package:rapa_track_mobile_app/app/pages/room/room_list_page.dart';
import 'package:rapa_track_mobile_app/app/services/notification_service.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/states/authentication_state.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';
import 'package:rapa_track_mobile_app/app/utils/navigation_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _reservationService = ReservationService();
  final _notificationService = NotificationService();

  int _totalReservations = 0;
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _todayCount = 0;
  int _unreadNotifications = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    _loadUnreadNotifications();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final today = _todayString;
      final results = await Future.wait([
        _reservationService.getReservationList(),
        _reservationService.getReservationList(
          status: ReservationStatus.pending.name,
        ),
        _reservationService.getReservationList(
          status: ReservationStatus.approved.name,
        ),
        _reservationService.getReservationList(dateFrom: today, dateTo: today),
      ]);
      if (mounted) {
        setState(() {
          _totalReservations = results[0].reservations.length;
          _pendingCount = results[1].reservations.length;
          _approvedCount = results[2].reservations.length;
          _todayCount = results[3].reservations.length;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  String get _todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout,
              size: AppSizes.iconXl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Keluar',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await AuthenticationState().logout();
      if (!mounted) return;
      NavigationHandler.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthenticationState().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(user),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadDashboardStats(),
            _loadUnreadNotifications(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserCard(user),
              _buildQuickActionsSection(user),
              _buildStatsSection(),
              const SizedBox(height: AppSizes.xxxl),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateReservation(user),
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Buat Reservasi',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Profile user) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withAlpha(18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                _buildAppBarLogoutButton(),
                const Expanded(child: _AppBarTitle()),
                _buildAppBarNotificationButton(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarLogoutButton() {
    return IconButton(
      icon: const Icon(Icons.logout, color: AppColors.error),
      tooltip: 'Keluar',
      onPressed: _confirmLogout,
    );
  }

  Widget _buildAppBarNotificationButton(Profile user) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Notifikasi',
          onPressed: () => _navigateToNotifications(user),
        ),
        if (_unreadNotifications > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserCard(Profile user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.sm,
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildUserAvatar(user),
          const SizedBox(width: AppSizes.md),
          Expanded(child: _buildUserInfo(user)),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(Profile user) {
    return Container(
      width: AppSizes.avatarXl,
      height: AppSizes.avatarXl,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            fontSize: AppSizes.fontXl,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(Profile user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: const TextStyle(
            fontSize: AppSizes.fontMd,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSizes.xxs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          ),
          child: Text(
            user.isAdmin ? 'Administrator' : (user.role?.label ?? 'Karyawan'),
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xxs),
        Text(
          DateFormatter.fullDate(DateTime.now()),
          style: const TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(Profile user) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _buildQuickActionsList(user),
        ],
      ),
    );
  }

  Widget _buildQuickActionsList(Profile user) {
    final actions = [
      _QuickAction(
        icon: Icons.calendar_month_outlined,
        label: 'Lihat Kalender',
        description: 'Cek jadwal dan ketersediaan ruangan',
        color: AppColors.primaryLight,
        onTap: () => _navigateToCalendar(user),
      ),
      _QuickAction(
        icon: Icons.meeting_room_outlined,
        label: 'Daftar Ruangan',
        description: 'Informasi ruang rapat yang tersedia',
        color: AppColors.success,
        onTap: () => _navigateToRoomList(user),
      ),
      _QuickAction(
        icon: Icons.list_alt_outlined,
        label: 'Reservasi Saya',
        description: 'Riwayat dan status pemesanan',
        color: AppColors.warning,
        onTap: () => _navigateToReservationList(user),
      ),
      _QuickAction(
        icon: Icons.feedback_outlined,
        label: 'Keluhan',
        description: 'Laporkan kendala fasilitas ruangan',
        color: AppColors.error,
        onTap: () => _navigateToComplaintList(user),
      ),
    ];

    return Card(
      elevation: AppSizes.elevationSm,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            _buildActionTile(actions[i]),
            if (i < actions.length - 1)
              const Divider(
                height: 1,
                indent: AppSizes.lg + AppSizes.xl + AppSizes.md,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile(_QuickAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.md,
        ),
        child: Row(
          children: [
            Container(
              width: AppSizes.xl + AppSizes.sm,
              height: AppSizes.xl + AppSizes.sm,
              decoration: BoxDecoration(
                color: action.color.withAlpha(25),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.description,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXs,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textDisabled,
              size: AppSizes.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        0,
        AppSizes.lg,
        AppSizes.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Reservasi',
            style: TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          if (_isLoadingStats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.xl),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.md,
              crossAxisSpacing: AppSizes.md,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  icon: Icons.event_note_outlined,
                  label: 'Total Reservasi',
                  value: '$_totalReservations',
                  color: AppColors.primary,
                ),
                _buildStatCard(
                  icon: Icons.pending_actions_outlined,
                  label: 'Menunggu',
                  value: '$_pendingCount',
                  color: AppColors.warning,
                ),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Disetujui',
                  value: '$_approvedCount',
                  color: AppColors.success,
                ),
                _buildStatCard(
                  icon: Icons.today_outlined,
                  label: 'Hari Ini',
                  value: '$_todayCount',
                  color: AppColors.primaryDark,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            icon,
            color: AppColors.white.withAlpha(200),
            size: AppSizes.iconSm,
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppSizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.white.withAlpha(200),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreateReservation(Profile user) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateReservationWizardPage(currentUser: user),
      ),
    );
    if (result == true) _loadDashboardStats();
  }

  void _navigateToReservationList(Profile user) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ReservationListPage(user: user)));
  }

  void _navigateToRoomList(Profile user) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RoomListPage(user: user)));
  }

  void _navigateToCalendar(Profile user) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CalendarPage(user: user)));
  }

  void _navigateToComplaintList(Profile user) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ComplaintListPage(user: user)));
  }

  void _navigateToNotifications(Profile user) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => NotificationListPage(user: user)),
        )
        .then((_) => _loadUnreadNotifications());
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'RapaTrack',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });
}
