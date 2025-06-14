import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/theme/app_colors.dart';
import 'package:room_reservation_mobile_app/app/theme/app_sizes.dart';
import 'package:room_reservation_mobile_app/app/ui_items/app_card.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onReserve;

  const RoomCard({super.key, required this.room, this.onTap, this.onReserve});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room image
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusXs),
              image: DecorationImage(
                image: NetworkImage(room.imageUrl),
                fit: BoxFit.cover,
                onError: (_, __) => Container(
                  color: AppColors.shimmer,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary,
                      size: AppSizes.iconLg,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Room name
          Text(
            room.name ?? 'Unnamed Room',
            style: theme.textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.xs),

          // Room capacity
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: AppSizes.iconSm,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                '${room.capacity ?? 0} orang',
                style: theme.textTheme.bodyMedium,
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
                  room.location ?? 'Unknown location',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
