import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';

/// Widget untuk menampilkan status badge reservasi
class ReservationStatusBadge extends StatelessWidget {
  final ReservationStatus status;
  final bool showDescription;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const ReservationStatusBadge({
    super.key,
    required this.status,
    this.showDescription = false,
    this.fontSize = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  status.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (showDescription) ...[
                  const SizedBox(height: 4),
                  Text(
                    status.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: fontSize - 2,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget untuk menampilkan status sebagai chip
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
      constraints: const BoxConstraints(maxWidth: 200),
      child: Chip(
        side: BorderSide.none,
        avatar: showIcon
            ? Icon(status.icon, size: 16, color: Colors.white)
            : null,
        label: Text(
          status.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        backgroundColor: status.color,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Widget untuk status indicator dengan timeline
class ReservationStatusTimeline extends StatelessWidget {
  final ReservationStatus status;

  const ReservationStatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Special case for rejected
    if (status == ReservationStatus.rejected) {
      return _buildSpecialStatusBox(
        icon: Icons.block,
        color: Colors.red,
        title: 'Ditolak',
        subtitle: 'Reservasi telah ditolak oleh admin',
      );
    }

    // Special case for cancelled
    if (status == ReservationStatus.cancelled) {
      return _buildSpecialStatusBox(
        icon: Icons.cancel,
        color: Colors.red,
        title: 'Dibatalkan',
        subtitle: 'Reservasi telah dibatalkan',
      );
    }

    final steps = [
      _TimelineStep(label: 'Pending', status: ReservationStatus.pending),
      _TimelineStep(label: 'Disetujui', status: ReservationStatus.approved),
      _TimelineStep(label: 'Selesai', status: ReservationStatus.completed),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _buildStepCircle(steps[i], steps),
              if (i < steps.length - 1) _buildConnector(steps[i + 1], steps),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialStatusBox({
    required IconData icon,
    required MaterialColor color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: color.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isStepActive(_TimelineStep step, List<_TimelineStep> steps) {
    final currentIndex = steps.indexWhere((s) => s.status == status);
    final stepIndex = steps.indexWhere((s) => s.status == step.status);
    return stepIndex <= currentIndex;
  }

  Widget _buildStepCircle(_TimelineStep step, List<_TimelineStep> steps) {
    final isActive = _isStepActive(step, steps);
    final isCurrent = step.status == status;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.green : Colors.grey.shade300,
            border: Border.all(
              color: isCurrent ? Colors.green.shade700 : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            isActive ? Icons.check : Icons.circle,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            step.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(_TimelineStep nextStep, List<_TimelineStep> steps) {
    final isActive = _isStepActive(nextStep, steps);

    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(top: 16),
      color: isActive ? Colors.green : Colors.grey.shade300,
    );
  }
}

class _TimelineStep {
  final String label;
  final ReservationStatus status;

  _TimelineStep({required this.label, required this.status});
}
