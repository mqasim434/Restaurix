import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';

/// Generic placeholder until a feature module replaces this route.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    this.subtitle = 'This screen will be built in a upcoming module.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_outlined,
              size: spacing.xxl + spacing.lg,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: spacing.lg),
            Text(
              title,
              style: typography.headlineSmall.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.sm),
            Text(
              subtitle,
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.md),
            Text(
              AppConstants.appName,
              style: typography.labelMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
