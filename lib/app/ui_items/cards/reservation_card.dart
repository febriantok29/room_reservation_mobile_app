import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/models/reservation.dart';
import 'package:rapa_track_mobile_app/app/services/reservation_service.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/reservation_status_badge.dart';

class ReservationCard extends StatefulWidget {
  final Reservation reservation;
  final Profile user;
  final VoidCallback? onRefresh;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.user,
    this.onRefresh,
  });

  @override
  State<ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<ReservationCard> {
  final _service = ReservationService();

  Reservation get _r => widget.reservation;
  ReservationStatus get _status => _r.status;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          onTap: _showDetail,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: _status.color),
                  Expanded(child: _buildCardContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(),
          const SizedBox(height: AppSizes.sm),
          _buildInfoRow(Icons.schedule_outlined, _r.formattedRange),
          const SizedBox(height: AppSizes.xxs),
          _buildInfoRow(
            Icons.group_outlined,
            '${_r.visitorCount ?? 1} orang',
          ),
          if (_r.purpose != null && _r.purpose!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xxs),
            _buildInfoRow(
              Icons.description_outlined,
              _r.purpose!,
              maxLines: 2,
            ),
          ],
          if (widget.user.isAdmin && _r.user != null) ...[
            const SizedBox(height: AppSizes.xxs),
            _buildInfoRow(Icons.person_outline, _r.user!.name),
          ],
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _r.room?.name ?? 'Ruangan tidak diketahui',
            style: const TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        ReservationStatusChip(status: _status),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int? maxLines}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textDisabled),
        const SizedBox(width: AppSizes.xs),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.textSecondary,
            ),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    final buttons = _buildButtons();
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.md),
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.sm),
            Expanded(child: buttons[i]),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildButtons() {
    final buttons = <Widget>[];

    if (widget.user.isAdmin) {
      if (_status.canBeApproved) {
        buttons.add(_actionButton(
          label: 'Setujui',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          onPressed: () => _confirmAction(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            title: 'Setujui Reservasi',
            message: 'Apakah Anda yakin ingin menyetujui reservasi ruangan ini?',
            action: () => _service.approveReservation(_r.id!),
            loadingText: 'Menyetujui reservasi...',
            successText: 'Reservasi berhasil disetujui.',
            successIcon: Icons.check_circle,
            successColor: AppColors.success,
          ),
        ));
        buttons.add(_actionButton(
          label: 'Tolak',
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          onPressed: () => _confirmAction(
            icon: Icons.cancel_outlined,
            iconColor: AppColors.error,
            title: 'Tolak Reservasi',
            message: 'Apakah Anda yakin ingin menolak reservasi ini?',
            action: () => _service.rejectReservation(_r.id!),
            loadingText: 'Menolak reservasi...',
            successText: 'Reservasi berhasil ditolak.',
            successIcon: Icons.block,
            successColor: AppColors.error,
          ),
        ));
      }

      if (_status.canBeCompleted) {
        buttons.add(_actionButton(
          label: 'Selesaikan',
          icon: Icons.done_all,
          color: AppColors.primary,
          onPressed: () => _confirmAction(
            icon: Icons.done_all,
            iconColor: AppColors.primary,
            title: 'Selesaikan Reservasi',
            message: 'Tandai reservasi ini telah selesai digunakan?',
            action: () => _service.completeReservation(_r.id!),
            loadingText: 'Menyelesaikan reservasi...',
            successText: 'Reservasi berhasil diselesaikan.',
            successIcon: Icons.check_circle,
            successColor: AppColors.primary,
          ),
        ));
      }
    }

    final showCancel = _status.canBeCancelled &&
        !(widget.user.isAdmin && _status == ReservationStatus.pending);

    if (showCancel) {
      buttons.add(_actionButton(
        label: 'Batalkan',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        onPressed: () => _confirmAction(
          icon: Icons.cancel_outlined,
          iconColor: AppColors.error,
          title: 'Batalkan Reservasi',
          message: 'Apakah Anda yakin ingin membatalkan pengajuan ini?',
          action: () => _service.cancelReservation(_r.id!),
          loadingText: 'Membatalkan reservasi...',
          successText: 'Reservasi berhasil dibatalkan.',
          successIcon: Icons.cancel,
          successColor: AppColors.error,
        ),
      ));
    }

    return buttons;
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _confirmAction({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required Future<Reservation> Function() action,
    required String loadingText,
    required String successText,
    required IconData successIcon,
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
                color: AppColors.textPrimary,
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

    _performAction(
      action: action,
      loadingText: loadingText,
      successText: successText,
      successIcon: successIcon,
      successColor: successColor,
    );
  }

  Future<void> _performAction({
    required Future<Reservation> Function() action,
    required String loadingText,
    required String successText,
    required IconData successIcon,
    required Color successColor,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSizes.md),
            Text(
              loadingText,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
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
              Icon(successIcon, size: AppSizes.iconXl, color: successColor),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Berhasil',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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

      widget.onRefresh?.call();
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
              const Icon(
                Icons.error_outline,
                size: AppSizes.iconXl,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSizes.md),
              const Text(
                'Gagal',
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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

  void _showDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _buildDetailSheet(scrollController),
      ),
    );
  }

  Widget _buildDetailSheet(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.md,
        AppSizes.lg,
        AppSizes.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Reservasi',
                      style: const TextStyle(
                        fontSize: AppSizes.fontXs,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    Text(
                      _r.room?.name ?? 'Ruangan tidak diketahui',
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
              ReservationStatusChip(status: _status),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: _status.color.withAlpha(15),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: _status.color.withAlpha(60)),
            ),
            child: ReservationStatusBadge(
              status: _status,
              showDescription: true,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.lg),
          _buildSheetRow(
            Icons.meeting_room_outlined,
            'Ruangan',
            _r.room?.name ?? '-',
          ),
          if (_r.room?.location != null)
            _buildSheetRow(
              Icons.location_on_outlined,
              'Lokasi',
              _r.room!.location,
            ),
          _buildSheetRow(
            Icons.schedule_outlined,
            'Waktu',
            _r.formattedRange,
          ),
          _buildSheetRow(
            Icons.group_outlined,
            'Jumlah Tamu',
            '${_r.visitorCount ?? 0} orang',
          ),
          if (_r.purpose != null && _r.purpose!.isNotEmpty)
            _buildSheetRow(
              Icons.description_outlined,
              'Keperluan',
              _r.purpose!,
            ),
          if (_r.user != null)
            _buildSheetRow(
              Icons.person_outline,
              'Pemohon',
              _r.user!.name,
            ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'Alur Status',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ReservationStatusTimeline(status: _status),
        ],
      ),
    );
  }

  Widget _buildSheetRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
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
}
