import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/theme/app_sizes.dart';

/// Status badge yang konsisten untuk seluruh aplikasi
class StatusBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final double? height;

  const StatusBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height ?? AppSizes.buttonHeightSm,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        border: Border.all(
          color: color ?? theme.colorScheme.primary,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color ?? theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
