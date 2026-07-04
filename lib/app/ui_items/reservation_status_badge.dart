import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/enums/reservation_status.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class ReservationStatusBadge extends StatelessWidget {
  final ReservationStatus status;
  final bool showDescription;

  const ReservationStatusBadge({
    super.key,
    required this.status,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(status.icon, size: AppSizes.iconSm, color: status.color),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status.displayName,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: status.color,
                ),
              ),
              if (showDescription) ...[
                const SizedBox(height: 2),
                Text(
                  status.description,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ReservationStatusChip extends StatelessWidget {
  final ReservationStatus status;
  final bool showIcon;

  const ReservationStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: status.color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
        border: Border.all(color: status.color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: 13, color: status.color),
            const SizedBox(width: AppSizes.xxs),
          ],
          Flexible(
            child: Text(
              status.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: status.color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class ReservationStatusTimeline extends StatelessWidget {
  final ReservationStatus status;

  const ReservationStatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == ReservationStatus.rejected ||
        status == ReservationStatus.cancelled) {
      return _buildTerminalBox();
    }

    final steps = [
      _Step('Pending', ReservationStatus.pending),
      _Step('Disetujui', ReservationStatus.approved),
      _Step('Selesai', ReservationStatus.completed),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _buildStepNode(steps[i], steps),
              if (i < steps.length - 1) _buildConnector(steps[i + 1], steps),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalBox() {
    final isRejected = status == ReservationStatus.rejected;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            isRejected ? Icons.block : Icons.cancel,
            color: AppColors.error,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRejected ? 'Ditolak' : 'Dibatalkan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontSize: AppSizes.fontSm,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRejected
                      ? 'Reservasi telah ditolak oleh admin'
                      : 'Reservasi telah dibatalkan',
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isActive(_Step step, List<_Step> steps) {
    final current = steps.indexWhere((s) => s.status == status);
    final idx = steps.indexWhere((s) => s.status == step.status);
    return idx <= current;
  }

  Widget _buildStepNode(_Step step, List<_Step> steps) {
    final isActive = _isActive(step, steps);
    final isCurrent = step.status == status;
    final color = isActive ? AppColors.success : AppColors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isCurrent ? AppColors.success : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            isActive ? Icons.check : Icons.circle,
            size: 16,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        SizedBox(
          width: 60,
          child: Text(
            step.label,
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.textPrimary : AppColors.textDisabled,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(_Step nextStep, List<_Step> steps) {
    final isActive = _isActive(nextStep, steps);
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(top: 15),
      color: isActive ? AppColors.success : AppColors.border,
    );
  }
}

class _Step {
  final String label;
  final ReservationStatus status;
  const _Step(this.label, this.status);
}
