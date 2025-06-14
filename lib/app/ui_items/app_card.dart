import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/theme/app_colors.dart';
import 'package:room_reservation_mobile_app/app/theme/app_sizes.dart';

/// Card yang konsisten untuk seluruh aplikasi
class AppCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool isLoading;
  final Color? color;
  final double? elevation;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    this.title,
    required this.child,
    this.isLoading = false,
    this.color,
    this.elevation,
    this.padding,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: color ?? AppColors.surface,
      elevation: elevation ?? AppSizes.elevationSm,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSizes.radiusSm),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
              ],
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.lg),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                child,
            ],
          ),
        ),
      ),
    );
  }
}
