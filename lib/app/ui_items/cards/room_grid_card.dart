import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

/// Kartu grid untuk ruangan di list page (admin & employee).
///
/// Menampilkan gambar (dengan placeholder), nama, lantai, kapasitas,
/// status badge (maintenance/deleted), dan tombol edit untuk admin.
class RoomGridCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const RoomGridCard({super.key, required this.room, this.onTap, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isMaintenance = room.isMaintenance == true;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImage(),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.name ?? '(Tanpa Nama)',
                              style: const TextStyle(
                                fontSize: AppSizes.fontSm,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: AppSizes.iconXs,
                                color: AppColors.primary,
                              ),
                              onPressed: onEdit,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: AppSizes.iconMd,
                                minHeight: AppSizes.iconMd,
                              ),
                              tooltip: 'Edit',
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              room.location,
                              style: const TextStyle(
                                fontSize: AppSizes.fontXs,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xxs),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 12,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: room.hasImage
          ? Image.network(
              room.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.lightGrey,
                child: const Center(
                  child: Icon(
                    Icons.meeting_room_outlined,
                    size: AppSizes.iconXl,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            )
          : Container(
              color: AppColors.lightGrey,
              child: const Center(
                child: Icon(
                  Icons.meeting_room_outlined,
                  size: AppSizes.iconXl,
                  color: AppColors.textDisabled,
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
