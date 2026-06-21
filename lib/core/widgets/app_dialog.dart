import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDanger = false,
    this.showActions = true,
  });

  final String title;
  final Widget? content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDanger;
  final bool showActions;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Widget? content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDanger = false,
    bool showActions = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDanger: isDanger,
        showActions: showActions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return AlertDialog(
      title: Text(
        title,
        style: typography.titleLarge.copyWith(color: colors.onSurface),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      content: content,
      actions: showActions
          ? [
              AppButton(
                label: cancelLabel,
                variant: AppButtonVariant.ghost,
                onPressed: () {
                  onCancel?.call();
                  Navigator.of(context).pop(false);
                },
              ),
              AppButton(
                label: confirmLabel,
                variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary,
                onPressed: () {
                  onConfirm?.call();
                  Navigator.of(context).pop(true);
                },
              ),
            ]
          : null,
      actionsPadding: EdgeInsets.fromLTRB(
        spacing.md,
        0,
        spacing.md,
        spacing.md,
      ),
    );
  }
}
