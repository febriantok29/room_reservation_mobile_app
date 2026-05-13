import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/enums/reservation_status.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';

/// Widget untuk menampilkan action buttons berdasarkan status reservasi
///
/// Buttons yang ditampilkan:
/// - PENDING: Approve, Reject (admin), Cancel (user)
/// - APPROVED: Complete (admin), Cancel (user)
/// - COMPLETED/CANCELLED/REJECTED: No actions (view only)
class ReservationActionButtons extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final VoidCallback? onCancel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onView;

  const ReservationActionButtons({
    super.key,
    required this.reservation,
    this.isAdmin = false,
    this.onCancel,
    this.onApprove,
    this.onReject,
    this.onComplete,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final status = reservation.status;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // View button (always available)
        if (onView != null)
          _ActionButton(
            label: 'Lihat Detail',
            icon: Icons.visibility,
            color: Colors.blue,
            onPressed: onView!,
          ),

        // Cancel button (pending, approved)
        if (status.canBeCancelled && onCancel != null)
          _ActionButton(
            label: 'Batalkan',
            icon: Icons.cancel,
            color: Colors.red,
            onPressed: onCancel!,
          ),

        // Approve button (pending, admin only)
        if (status.canBeApproved && isAdmin && onApprove != null)
          _ActionButton(
            label: 'Setujui',
            icon: Icons.check_circle,
            color: Colors.green,
            onPressed: onApprove!,
          ),

        // Reject button (pending, admin only)
        if (status.canBeRejected && isAdmin && onReject != null)
          _ActionButton(
            label: 'Tolak',
            icon: Icons.block,
            color: Colors.orange,
            onPressed: onReject!,
          ),

        // Complete button (approved, admin only)
        if (status.canBeCompleted && isAdmin && onComplete != null)
          _ActionButton(
            label: 'Selesaikan',
            icon: Icons.done_all,
            color: Colors.teal,
            onPressed: onComplete!,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
