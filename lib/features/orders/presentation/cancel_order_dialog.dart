import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

class CancelOrderDialog extends StatefulWidget {
  const CancelOrderDialog({
    super.key,
    this.requiresRefundNote = false,
  });

  final bool requiresRefundNote;

  static Future<({String reason, String? refundNote})?> show(
    BuildContext context, {
    bool requiresRefundNote = false,
  }) {
    return showDialog<({String reason, String? refundNote})>(
      context: context,
      builder: (context) =>
          CancelOrderDialog(requiresRefundNote: requiresRefundNote),
    );
  }

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  final _reasonController = TextEditingController();
  final _refundController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return AlertDialog(
      title: Text(
        'Cancel order',
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The order will remain in history as cancelled. This cannot be undone.',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Cancellation reason',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (widget.requiresRefundNote) ...[
              SizedBox(height: spacing.md),
              TextField(
                controller: _refundController,
                decoration: const InputDecoration(
                  labelText: 'Refund note (recommended for prepaid orders)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Keep order',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Cancel order',
          variant: AppButtonVariant.danger,
          onPressed: _submit,
        ),
      ],
      actionsPadding: EdgeInsets.fromLTRB(
        spacing.md,
        0,
        spacing.md,
        spacing.md,
      ),
    );
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Reason is required');
      return;
    }

    Navigator.of(context).pop((
      reason: reason,
      refundNote: _refundController.text.trim().isEmpty
          ? null
          : _refundController.text.trim(),
    ));
  }
}
