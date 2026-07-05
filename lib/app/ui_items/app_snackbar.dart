import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

enum SnackBarType { success, error, warning, info }

/// Snackbar yang konsisten untuk seluruh aplikasi
class AppSnackBar extends SnackBar {
  AppSnackBar({
    super.key,
    required String message,
    SnackBarType type = SnackBarType.success,
    Duration? duration,
  }) : super(
         content: Text(
           message,
           style: const TextStyle(
             color: AppColors.white,
             fontSize: AppSizes.fontSm,
           ),
         ),
         backgroundColor: _getBackgroundColor(type),
         duration: duration ?? const Duration(seconds: 3),
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(AppSizes.radiusXs),
         ),
         margin: const EdgeInsets.all(AppSizes.lg),
       );

  static Color _getBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppColors.success;
      case SnackBarType.error:
        return AppColors.error;
      case SnackBarType.warning:
        return AppColors.warning;
      case SnackBarType.info:
        return AppColors.info;
    }
  }

  /// Helper untuk menampilkan snackbar
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.success,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar(message: message, type: type, duration: duration),
    );
  }
}
