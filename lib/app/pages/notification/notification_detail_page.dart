import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/notification_model.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/app_card.dart';
import 'package:rapa_track_mobile_app/app/ui_items/status_badge.dart';
import 'package:rapa_track_mobile_app/app/utils/date_formatter.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  bool get _hasMetadata =>
      notification.data != null && notification.data!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Notifikasi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.xl),
          _buildContentCard(),
          if (_hasMetadata) ...[
            const SizedBox(height: AppSizes.lg),
            _buildMetadataCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: AppSizes.avatarXl + AppSizes.xl,
          height: AppSizes.avatarXl + AppSizes.xl,
          decoration: BoxDecoration(
            color: notification.type.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.type.icon,
            color: notification.type.color,
            size: AppSizes.iconXl,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        StatusBadge(
          text: notification.type.displayName,
          color: notification.type.color,
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.title ?? notification.type.displayName,
            style: const TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (notification.body != null) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              notification.body!,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: AppSizes.iconXs,
                color: AppColors.textDisabled,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                notification.createdAt != null
                    ? DateFormatter.fullDateTime(notification.createdAt!)
                    : '-',
                style: const TextStyle(
                  fontSize: AppSizes.fontXs,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return AppCard(
      title: 'Detail Tambahan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notification.data!.entries
            .map((e) => _buildMetadataRow(e.key, e.value))
            .toList(),
      ),
    );
  }

  Widget _buildMetadataRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _humanizeKey(key),
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Flexible(
            child: Text(
              _formatValue(value),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: AppSizes.fontXs,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _humanizeKey(String key) {
    final words = key.replaceAll('_', ' ').split(' ');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Ya' : 'Tidak';
    if (value is Map) {
      return value['name']?.toString() ?? value.values.first?.toString() ?? '-';
    }
    if (value is List) return value.join(', ');
    return '$value';
  }
}
