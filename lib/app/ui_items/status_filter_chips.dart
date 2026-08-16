import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/pages/report/report_definitions.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

/// Chip status yang bisa di-toggle on/off langsung, tanpa dialog.
class StatusFilterChips extends StatelessWidget {
  final List<ReportStatusOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  const StatusFilterChips({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  void _toggle(String value) {
    final next = List<String>.from(selectedValues);
    next.contains(value) ? next.remove(value) : next.add(value);
    onChanged(next);
  }

  void _toggleAll() {
    final allSelected = selectedValues.length == options.length;
    onChanged(allSelected ? [] : options.map((o) => o.value).toList());
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary.withAlpha(30),
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
      ),
      labelStyle: TextStyle(
        fontSize: AppSizes.fontSm,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedValues.length == options.length;

    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: [
        _buildChip(label: 'Semua', isSelected: allSelected, onTap: _toggleAll),
        ...options.map((option) {
          final isSelected = selectedValues.contains(option.value);
          return _buildChip(
            label: option.label,
            isSelected: isSelected,
            onTap: () => _toggle(option.value),
          );
        }),
      ],
    );
  }
}
