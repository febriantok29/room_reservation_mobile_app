import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String cancelLabel = 'Batal',
    String confirmLabel = 'Lanjutkan',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.all(AppSizes.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconXl, color: iconColor),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
