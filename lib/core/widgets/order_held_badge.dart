import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Operational hold flag — distinct from order status.
class OrderHeldBadge extends StatelessWidget {
  const OrderHeldBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spacing = context.appSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.18),
        borderRadius: context.appRadius.smBorder,
        border: Border.all(color: colors.warning),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? spacing.xs : spacing.sm,
          vertical: spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_outline_rounded,
              size: compact ? 14 : 16,
              color: colors.warning,
            ),
            SizedBox(width: spacing.xs),
            Text(
              'Held',
              style: (compact ? typography.labelSmall : typography.labelMedium)
                  .copyWith(color: colors.warning),
            ),
          ],
        ),
      ),
    );
  }
}
