import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;
    final typography = context.appTypography;

    final (background, foreground, border) = _resolveColors(colors);
    final verticalPadding = switch (size) {
      AppButtonSize.small => spacing.xs,
      AppButtonSize.medium => spacing.sm,
      AppButtonSize.large => spacing.md,
    };
    final horizontalPadding = switch (size) {
      AppButtonSize.small => spacing.sm,
      AppButtonSize.medium => spacing.md,
      AppButtonSize.large => spacing.lg,
    };
    final textStyle = switch (size) {
      AppButtonSize.small => typography.labelMedium,
      AppButtonSize.medium => typography.labelLarge,
      AppButtonSize.large => typography.titleSmall,
    };

    final enabled = onPressed != null && !isLoading;

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: spacing.md,
            height: spacing.md,
            child: CircularProgressIndicator(
              strokeWidth: spacing.xs / 2,
              color: foreground,
            ),
          ),
          SizedBox(width: spacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: spacing.md, color: foreground),
          SizedBox(width: spacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: textStyle.copyWith(color: foreground),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );

    return Material(
      color: enabled ? background : colors.disabledSurface,
      borderRadius: radius.mdBorder,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: radius.mdBorder,
        hoverColor: colors.hover,
        splashColor: colors.pressed,
        child: Container(
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: radius.mdBorder,
            border: border != null ? Border.all(color: border) : null,
          ),
          child: child,
        ),
      ),
    );
  }

  (Color background, Color foreground, Color? border) _resolveColors(
    AppColorsTheme colors,
  ) {
    return switch (variant) {
      AppButtonVariant.primary => (
          colors.primary,
          colors.onPrimary,
          null,
        ),
      AppButtonVariant.secondary => (
          colors.surface,
          colors.primary,
          colors.primary,
        ),
      AppButtonVariant.danger => (
          colors.error,
          colors.onError,
          null,
        ),
      AppButtonVariant.ghost => (
          colors.transparent,
          colors.onSurface,
          colors.border,
        ),
    };
  }
}
