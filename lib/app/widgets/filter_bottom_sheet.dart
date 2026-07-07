import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class FilterBottomSheet extends StatelessWidget {
  final String title;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final String applyLabel;
  final List<Widget> children;

  const FilterBottomSheet({
    super.key,
    required this.title,
    required this.onReset,
    required this.onApply,
    this.applyLabel = 'Terapkan Filter',
    required this.children,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.xl,
          AppSizes.md,
          AppSizes.xl,
          AppSizes.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: AppSizes.lg),
            _buildHeader(),
            const SizedBox(height: AppSizes.lg),
            ...children,
            const SizedBox(height: AppSizes.sm),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontLg,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: onReset,
          child: const Text(
            'Reset',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onApply,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, AppSizes.buttonHeightLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        child: Text(
          applyLabel,
          style: const TextStyle(
            fontSize: AppSizes.fontMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class FilterSection extends StatelessWidget {
  final String label;
  final Widget child;

  const FilterSection({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: AppSizes.fontXs,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        child,
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }
}

class FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class FilterDateField extends StatelessWidget {
  final String label;
  final String? valueText;
  final VoidCallback onTap;

  const FilterDateField({
    super.key,
    required this.label,
    this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontXs,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valueText ?? 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: AppSizes.fontSm,
                      fontWeight: valueText != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: valueText != null
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.iconXs,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
