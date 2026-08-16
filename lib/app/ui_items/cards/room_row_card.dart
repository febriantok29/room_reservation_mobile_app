import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

/// Kartu baris (horizontal) untuk ruangan di list page.
///
/// Menampilkan strip status warna, ikon, nama, lantai, kapasitas,
/// status badge (maintenance/deleted), dan tombol edit untuk admin.
class RoomRowCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const RoomRowCard({super.key, required this.room, this.onTap, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isMaintenance = room.isMaintenance == true;
    final statusColor = isMaintenance ? AppColors.warning : AppColors.primary;

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.sm),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
                            ),
                            child: Icon(
                              Icons.meeting_room,
                              size: AppSizes.iconLg,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  room.name ?? '(Tanpa Nama)',
                                  style: const TextStyle(
                                    fontSize: AppSizes.fontMd,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSizes.xxs),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      room.location,
                                      style: const TextStyle(
                                        fontSize: AppSizes.fontXs,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    const Icon(
                                      Icons.people_outline,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${room.capacity ?? '-'} orang',
                                      style: const TextStyle(
                                        fontSize: AppSizes.fontXs,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isMaintenance) ...[
                                  const SizedBox(height: AppSizes.xs),
                                  _buildBadge(
                                    Icons.build_outlined,
                                    'Dalam Perawatan',
                                    AppColors.warning,
                                  ),
                                ],
                                if (room.deletedAt != null) ...[
                                  const SizedBox(height: AppSizes.xs),
                                  _buildBadge(
                                    Icons.delete_outlined,
                                    'Dihapus ${room.deletedAtFormatted}',
                                    AppColors.error,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: AppSizes.iconSm,
                                color: AppColors.primary,
                              ),
                              onPressed: onEdit,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              tooltip: 'Edit',
                            ),
                          const Icon(
                            Icons.chevron_right,
                            size: AppSizes.iconMd,
                            color: AppColors.textDisabled,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSizes.xxs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
