import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = AppLoadingSize.medium,
  });

  final String? message;
  final AppLoadingSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    final indicatorSize = switch (size) {
      AppLoadingSize.small => spacing.lg,
      AppLoadingSize.medium => spacing.xl,
      AppLoadingSize.large => spacing.xxl,
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: spacing.xs,
              color: colors.primary,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: spacing.md),
            Text(
              message!,
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }
}

enum AppLoadingSize { small, medium, large }
