import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/pages/reservation/reservation_modal_bottom_sheet.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/reservation_status_badge.dart';

class ReservationDetailPage extends StatefulWidget {
  final String reservationId;
  final Profile user;

  const ReservationDetailPage({
    super.key,
    required this.reservationId,
    required this.user,
  });

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  final _service = ReservationService();

  Reservation? _reservation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _service.getReservationDetail(widget.reservationId);
      if (mounted) setState(() => _reservation = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Reservasi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: AppSizes.iconXl, color: AppColors.error),
            const SizedBox(height: AppSizes.lg),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.fontSm),
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_reservation == null) return const SizedBox.shrink();

    final r = _reservation!;
    final status = r.status;

    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBanner(r),
            const SizedBox(height: AppSizes.lg),
            _buildInfoCard(r),
            const SizedBox(height: AppSizes.lg),
            _buildTimelineCard(status),
            const SizedBox(height: AppSizes.lg),
            ..._buildActionButtons(r),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(Reservation r) {
    final status = r.status;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Reservasi',
                      style: TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    Text(
                      r.room?.name ?? 'Ruangan tidak diketahui',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              ReservationStatusChip(status: status),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: status.color.withAlpha(15),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: status.color.withAlpha(60)),
            ),
            child: ReservationStatusBadge(status: status, showDescription: true),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Reservation r) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRow(Icons.meeting_room_outlined, 'Ruangan', r.room?.name ?? '-'),
          if (r.room?.location != null)
            _buildRow(Icons.location_on_outlined, 'Lokasi', r.room!.location),
          _buildRow(Icons.schedule_outlined, 'Waktu', r.formattedRange),
          _buildRow(Icons.group_outlined, 'Jumlah Tamu', '${r.visitorCount ?? 0} orang'),
          if (r.purpose != null && r.purpose!.isNotEmpty)
            _buildRow(Icons.description_outlined, 'Keperluan', r.purpose!),
          if (r.user != null)
            _buildRow(Icons.person_outline, 'Pemohon', r.user!.name),
          if (r.createdAt != null)
            _buildRow(
              Icons.access_time_outlined,
              'Dibuat',
              '${r.createdAt!.day}/${r.createdAt!.month}/${r.createdAt!.year}',
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textDisabled),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(ReservationStatus status) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alur Status',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ReservationStatusTimeline(status: status),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(Reservation r) {
    final buttons = <Widget>[];

    if (widget.user.isAdmin && r.status.canBeApproved) {
      buttons.add(_actionButton(
        label: 'Setujui Reservasi',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        onPressed: () => _confirmAction(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
          title: 'Setujui Reservasi',
          message: 'Apakah Anda yakin ingin menyetujui reservasi ini?',
          action: () => _service.approveReservation(r.id!),
          successText: 'Reservasi berhasil disetujui.',
          successColor: AppColors.success,
        ),
      ));
      buttons.add(const SizedBox(height: AppSizes.sm));
      buttons.add(_actionButton(
        label: 'Tolak Reservasi',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        onPressed: () => _confirmAction(
          icon: Icons.cancel_outlined,
          iconColor: AppColors.error,
          title: 'Tolak Reservasi',
          message: 'Apakah Anda yakin ingin menolak reservasi ini?',
          action: () => _service.rejectReservation(r.id!),
          successText: 'Reservasi berhasil ditolak.',
          successColor: AppColors.error,
        ),
      ));
    }

    if (widget.user.isAdmin && r.status.canBeCompleted) {
      buttons.add(_actionButton(
        label: 'Tandai Selesai',
        icon: Icons.done_all,
        color: AppColors.primary,
        onPressed: () => _confirmAction(
          icon: Icons.done_all,
          iconColor: AppColors.primary,
          title: 'Selesaikan Reservasi',
          message: 'Tandai reservasi ini telah selesai digunakan?',
          action: () => _service.completeReservation(r.id!),
          successText: 'Reservasi berhasil diselesaikan.',
          successColor: AppColors.primary,
        ),
      ));
    }

    if (r.canBeRescheduledBy(widget.user)) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: AppSizes.sm));
      buttons.add(_actionButton(
        label: 'Jadwal Ulang',
        icon: Icons.edit_calendar_outlined,
        color: AppColors.primary,
        onPressed: () => _openReschedule(r),
      ));
    }

    final canCancel = r.status.canBeCancelled &&
        !(widget.user.isAdmin && r.status == ReservationStatus.pending);
    if (canCancel) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: AppSizes.sm));
      buttons.add(_actionButton(
        label: 'Batalkan Reservasi',
        icon: Icons.event_busy_outlined,
        color: AppColors.error,
        outlined: true,
        onPressed: () => _confirmAction(
          icon: Icons.event_busy_outlined,
          iconColor: AppColors.error,
          title: 'Batalkan Reservasi',
          message: 'Apakah Anda yakin ingin membatalkan pengajuan ini?',
          action: () => _service.cancelReservation(r.id!),
          successText: 'Reservasi berhasil dibatalkan.',
          successColor: AppColors.error,
        ),
      ));
    }

    if (buttons.isNotEmpty) buttons.add(const SizedBox(height: AppSizes.lg));
    return buttons;
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    if (outlined) {
      return SizedBox(
        height: AppSizes.buttonHeightLg,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
          ),
        ),
      );
    }
    return SizedBox(
      height: AppSizes.buttonHeightLg,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
        ),
      ),
    );
  }

  Future<void> _openReschedule(Reservation r) async {
    final result = await ReservationModalBottomSheet.show(
      context: context,
      user: widget.user,
      reservation: r,
    );

    if (result == true) _loadDetail();
  }

  Future<void> _confirmAction({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required Future<Reservation> Function() action,
    required String successText,
    required Color successColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconXl, color: iconColor),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Lanjutkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        contentPadding: EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: AppSizes.md),
            Text('Memproses...'),
          ],
        ),
      ),
    );

    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.all(AppSizes.xl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: AppSizes.iconXl, color: successColor),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Berhasil',
                style: TextStyle(fontSize: AppSizes.fontLg, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                successText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successColor,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.all(AppSizes.xl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: AppSizes.iconXl, color: AppColors.error),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Gagal',
                style: TextStyle(fontSize: AppSizes.fontLg, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
