import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';

/// Widget untuk menampilkan status badge reservasi
///
/// Menampilkan status dengan warna yang sesuai:
/// - CONFIRMED: Blue
/// - UPCOMING: Orange
/// - ONGOING: Green
/// - COMPLETED: Grey
/// - CANCELLED: Red
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

  Color _getColor() {
    final hex = status.colorHex.substring(1); // Remove #
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  }

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
              color: _getColor(),
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

/// Widget untuk menampilkan status sebagai chip (smaller version)
class ReservationStatusChip extends StatelessWidget {
  final ReservationStatus status;
  final bool showIcon;

  const ReservationStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  Color _getColor() {
    final hex = status.colorHex.substring(1);
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  }

  IconData _getIcon() {
    switch (status) {
      case ReservationStatus.confirmed:
        return Icons.check_circle_outline;
      case ReservationStatus.upcoming:
        return Icons.schedule;
      case ReservationStatus.ongoing:
        return Icons.play_circle_outline;
      case ReservationStatus.completed:
        return Icons.done_all;
      case ReservationStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Chip(
        side: BorderSide.none,
        avatar: showIcon
            ? Icon(_getIcon(), size: 16, color: Colors.white)
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
        backgroundColor: _getColor(),
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

  List<_TimelineStep> _getSteps() {
    return [
      _TimelineStep(
        label: 'Terkonfirmasi',
        status: ReservationStatus.confirmed,
      ),
      _TimelineStep(label: 'Akan Dimulai', status: ReservationStatus.upcoming),
      _TimelineStep(label: 'Berlangsung', status: ReservationStatus.ongoing),
      _TimelineStep(label: 'Selesai', status: ReservationStatus.completed),
    ];
  }

  bool _isStepActive(_TimelineStep step) {
    final currentIndex = _getCurrentIndex();
    final stepIndex = _getStepIndex(step.status);
    return stepIndex <= currentIndex;
  }

  int _getCurrentIndex() {
    switch (status) {
      case ReservationStatus.confirmed:
        return 0;
      case ReservationStatus.upcoming:
        return 1;
      case ReservationStatus.ongoing:
        return 2;
      case ReservationStatus.completed:
        return 3;
      case ReservationStatus.cancelled:
        return -1; // Special case
    }
  }

  int _getStepIndex(ReservationStatus s) {
    switch (s) {
      case ReservationStatus.confirmed:
        return 0;
      case ReservationStatus.upcoming:
        return 1;
      case ReservationStatus.ongoing:
        return 2;
      case ReservationStatus.completed:
        return 3;
      case ReservationStatus.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Special case for cancelled
    if (status == ReservationStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dibatalkan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reservasi telah dibatalkan',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final steps = _getSteps();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _buildStepCircle(steps[i]),
              if (i < steps.length - 1) _buildConnector(i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(_TimelineStep step) {
    final isActive = _isStepActive(step);
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

  Widget _buildConnector(int index) {
    final isActive = _isStepActive(_getSteps()[index + 1]);

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
