import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isFullWidth;
  final Color? color;
  final double? width;
  final double height;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.color,
    this.width,
    this.height = AppSizes.buttonHeightMd,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    final foreground = isOutlined ? buttonColor : AppColors.white;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: SizedBox(
              width: AppSizes.iconSm,
              height: AppSizes.iconSm,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.borderWidth,
                valueColor: AlwaysStoppedAnimation(foreground),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: Icon(icon, size: AppSizes.iconSm, color: foreground),
          ),
        Text(text),
      ],
    );

    final effectiveWidth = isFullWidth ? double.infinity : width;

    return SizedBox(
      width: effectiveWidth,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: buttonColor,
                side: BorderSide(color: buttonColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: buttonColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
              ),
              child: child,
            ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: effectiveColor),
        label: Text(
          label,
          style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600),
        ),
      );
    }

    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
