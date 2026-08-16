import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/room.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

/// Kartu baris (horizontal) untuk ruangan di list page & pemilihan ruangan.
///
/// Thumbnail persegi (aspect ratio 1) yang lebarnya proporsional via Expanded —
/// tanpa IntrinsicHeight/stretch sehingga aman di ListView. Strip status kiri
/// dibuat dengan Stack (bukan border) agar kompatibel dengan borderRadius.
class RoomRowCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool isSelected;
  final bool showChevron;

  const RoomRowCard({
    super.key,
    required this.room,
    this.onTap,
    this.onEdit,
    this.isSelected = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMaintenance = room.isMaintenance == true;
    final statusColor = isMaintenance ? AppColors.warning : AppColors.primary;
    final borderColor = isSelected ? AppColors.primary : AppColors.border;
    final borderWidth =
        isSelected ? AppSizes.borderWidthThick : AppSizes.borderWidth;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: statusColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md + 4,
                  AppSizes.md,
                  AppSizes.md,
                  AppSizes.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 2,
                      child: _buildThumbnail(),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      flex: 6,
                      child: _buildInfo(isMaintenance),
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(width: AppSizes.xs),
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
                    ],
                    if (showChevron)
                      const Icon(
                        Icons.chevron_right,
                        size: AppSizes.iconMd,
                        color: AppColors.textDisabled,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(bool isMaintenance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                room.name ?? '(Tanpa Nama)',
                style: const TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSizes.xs),
              const Icon(
                Icons.check_circle,
                size: AppSizes.iconSm,
                color: AppColors.primary,
              ),
            ],
          ],
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
            Flexible(
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
            const SizedBox(width: AppSizes.sm),
            const Icon(
              Icons.people_outline,
              size: 13,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 2),
            Text(
              '${room.capacity ?? '-'}',
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
    );
  }

  Widget _buildThumbnail() {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: room.hasImage
            ? Image.network(
                room.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _buildThumbnailPlaceholder(),
              )
            : _buildThumbnailPlaceholder(),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: AppColors.shimmer,
      child: const Center(
        child: Icon(
          Icons.meeting_room,
          size: AppSizes.iconLg,
          color: AppColors.textSecondary,
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
