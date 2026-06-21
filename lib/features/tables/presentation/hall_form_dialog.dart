import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/hall.dart';

class HallFormResult {
  const HallFormResult({required this.name});

  final String name;
}

class HallFormDialog extends StatefulWidget {
  const HallFormDialog({
    super.key,
    this.hall,
    this.title = 'Add Hall',
  });

  final Hall? hall;
  final String title;

  static Future<HallFormResult?> show(
    BuildContext context, {
    Hall? hall,
    String title = 'Add Hall',
  }) {
    return showDialog<HallFormResult>(
      context: context,
      builder: (context) => HallFormDialog(hall: hall, title: title),
    );
  }

  @override
  State<HallFormDialog> createState() => _HallFormDialogState();
}

class _HallFormDialogState extends State<HallFormDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hall?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return AlertDialog(
      title: Text(
        widget.title,
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: spacing.xxl * 5,
        child: AppTextField(
          controller: _nameController,
          label: 'Hall name',
          hint: 'e.g. Main Dining, Patio',
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(HallFormResult(name: name));
  }
}
