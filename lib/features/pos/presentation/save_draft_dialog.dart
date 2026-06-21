import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

class SaveDraftDialog extends StatefulWidget {
  const SaveDraftDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String?>(
      context: context,
      builder: (context) => const SaveDraftDialog(),
    );
  }

  @override
  State<SaveDraftDialog> createState() => _SaveDraftDialogState();
}

class _SaveDraftDialogState extends State<SaveDraftDialog> {
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return AlertDialog(
      title: Text(
        'Save as draft',
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'The current cart will be saved and cleared. Any reserved table stays held until the draft is resumed or discarded.',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.md),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'Table 5 - waiting on customer',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Save draft',
          onPressed: () {
            Navigator.of(context).pop(_labelController.text.trim());
          },
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
}
