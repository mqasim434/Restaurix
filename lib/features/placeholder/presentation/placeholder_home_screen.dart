import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appName,
              style: typography.displayMedium.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.lg),
            AppButton(
              label: 'Open Design System Preview',
              onPressed: () => context.go('/theme-preview'),
            ),
            SizedBox(height: spacing.sm),
            AppButton(
              label: 'Open Isar Debug',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go('/debug-isar'),
            ),
          ],
        ),
      ),
    );
  }
}
