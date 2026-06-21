import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/restaurant_table.dart';

class TableFormResult {
  const TableFormResult({
    required this.label,
    required this.capacity,
  });

  final String label;
  final int capacity;
}

class TableFormDialog extends StatefulWidget {
  const TableFormDialog({
    super.key,
    this.table,
    this.title = 'Add Table',
  });

  final RestaurantTable? table;
  final String title;

  static Future<TableFormResult?> show(
    BuildContext context, {
    RestaurantTable? table,
    String title = 'Add Table',
  }) {
    return showDialog<TableFormResult>(
      context: context,
      builder: (context) => TableFormDialog(table: table, title: title),
    );
  }

  @override
  State<TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<TableFormDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.table?.label ?? '');
    _capacityController = TextEditingController(
      text: (widget.table?.capacity ?? 4).toString(),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _capacityController.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _labelController,
              label: 'Table label',
              hint: 'e.g. T5',
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              controller: _capacityController,
              label: 'Capacity',
              hint: '4',
              keyboardType: TextInputType.number,
            ),
          ],
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
    final label = _labelController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim());
    if (label.isEmpty || capacity == null || capacity < 1) return;

    Navigator.of(context).pop(
      TableFormResult(label: label, capacity: capacity),
    );
  }
}
