import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

enum AppSnackbarType { success, error, info }

abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    final (background, foreground, icon) = switch (type) {
      AppSnackbarType.success => (
          colors.success,
          colors.onSuccess,
          AppIcons.success,
        ),
      AppSnackbarType.error => (
          colors.error,
          colors.onError,
          AppIcons.error,
        ),
      AppSnackbarType.info => (
          colors.secondary,
          colors.onSecondary,
          AppIcons.info,
        ),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: background,
        content: Row(
          children: [
            Icon(icon, color: foreground, size: spacing.lg - spacing.xs),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                message,
                style: typography.bodyMedium.copyWith(color: foreground),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.error);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.info);
}
