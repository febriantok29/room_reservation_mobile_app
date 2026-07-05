import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: AppSizes.fontXs,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color color;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.color = AppColors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSizes.lg),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: onTap != null
            ? InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                onTap: onTap,
                child: content,
              )
            : content,
      ),
    );
  }
}

class FormRowField extends StatelessWidget {
  final String label;
  final String? valueText;
  final String placeholder;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const FormRowField({
    super.key,
    required this.label,
    this.valueText,
    this.placeholder = 'Pilih',
    this.icon = Icons.chevron_right,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: enabled ? AppColors.white : AppColors.background,
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.lg,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              valueText ?? placeholder,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: valueText != null
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: valueText != null && enabled
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Icon(
            icon,
            size: AppSizes.iconSm,
            color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}

class ChoiceCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const ChoiceCard({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      icon: icon,
      controlIcon: isSelected
          ? Icons.radio_button_checked
          : Icons.radio_button_off,
    );
  }
}

class CheckCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const CheckCard({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectionCard(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      icon: icon,
      controlIcon: isSelected
          ? Icons.check_box
          : Icons.check_box_outline_blank,
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData controlIcon;

  const _SelectionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.controlIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(25)
              : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              controlIcon,
              size: AppSizes.iconSm,
              color: isSelected ? AppColors.primary : AppColors.textDisabled,
            ),
            const SizedBox(width: AppSizes.sm),
            if (icon != null) ...[
              Icon(
                icon,
                size: AppSizes.iconXs,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoftTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final String? suffixText;
  final String? helperText;

  const SoftTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.suffixText,
    this.helperText,
  });

  OutlineInputBorder _border({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      borderSide: color != null
          ? BorderSide(color: color, width: width)
          : BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          readOnly: readOnly,
          enabled: enabled,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontSize: AppSizes.fontSm),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textDisabled,
            ),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSecondary,
            ),
            helperText: helperText,
            counterText: '',
            filled: true,
            fillColor: readOnly || !enabled
                ? AppColors.background
                : AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(color: AppColors.primary, width: 1.5),
            errorBorder: _border(color: AppColors.error),
            focusedErrorBorder: _border(color: AppColors.error, width: 1.5),
          ),
        ),
      ],
    );
  }
}
