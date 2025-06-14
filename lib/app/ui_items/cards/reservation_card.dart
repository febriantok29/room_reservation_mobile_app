import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/extensions/reservation_extension.dart';
import 'package:room_reservation_mobile_app/app/models/reservation.dart';
import 'package:room_reservation_mobile_app/app/theme/app_colors.dart';
import 'package:room_reservation_mobile_app/app/theme/app_sizes.dart';
import 'package:room_reservation_mobile_app/app/ui_items/app_card.dart';
import 'package:room_reservation_mobile_app/app/ui_items/status_badge.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with room name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  reservation.room?.name ?? 'Unknown Room',
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              StatusBadge(
                text: reservation.formattedStatus,
                color: Color(
                  int.parse(reservation.statusColor.replaceFirst('#', '0xFF')),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Reservation time
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: AppSizes.iconSm,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  reservation.formattedRange,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),

          // Room location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: AppSizes.iconSm,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  reservation.room?.location ?? 'Unknown location',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),

          // Created time
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: AppSizes.iconSm,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  'Dibuat ${reservation.formattedCreatedAt}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
