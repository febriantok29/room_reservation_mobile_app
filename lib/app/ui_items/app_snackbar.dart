import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/theme/app_colors.dart';
import 'package:room_reservation_mobile_app/app/theme/app_sizes.dart';

/// Snackbar yang konsisten untuk seluruh aplikasi
class AppSnackBar extends SnackBar {
  AppSnackBar({
    super.key,
    required String message,
    bool isError = false,
    Duration? duration,
  }) : super(
         content: Text(
           message,
           style: const TextStyle(
             color: AppColors.white,
             fontSize: AppSizes.fontSm,
           ),
         ),
         backgroundColor: isError ? AppColors.error : AppColors.success,
         duration: duration ?? const Duration(seconds: 3),
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(AppSizes.radiusXs),
         ),
         margin: const EdgeInsets.all(AppSizes.lg),
       );

  /// Helper untuk menampilkan snackbar
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar(message: message, isError: isError, duration: duration),
    );
  }
}
