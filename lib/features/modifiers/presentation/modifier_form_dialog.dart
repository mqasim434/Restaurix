import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'modifier_price_format.dart';

class ModifierFormResult {
  const ModifierFormResult({
    required this.name,
    required this.priceDelta,
  });

  final String name;
  final double priceDelta;
}

class ModifierFormDialog extends StatefulWidget {
  const ModifierFormDialog({
    super.key,
    this.initialName,
    this.initialPriceDelta,
    this.title = 'Add Modifier',
  });

  final String? initialName;
  final double? initialPriceDelta;
  final String title;

  static Future<ModifierFormResult?> show(
    BuildContext context, {
    String? initialName,
    double? initialPriceDelta,
    String title = 'Add Modifier',
  }) {
    return showDialog<ModifierFormResult>(
      context: context,
      builder: (context) => ModifierFormDialog(
        initialName: initialName,
        initialPriceDelta: initialPriceDelta,
        title: title,
      ),
    );
  }

  @override
  State<ModifierFormDialog> createState() => _ModifierFormDialogState();
}

class _ModifierFormDialogState extends State<ModifierFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    final delta = widget.initialPriceDelta;
    _priceController = TextEditingController(
      text: delta != null
          ? (delta == delta.roundToDouble()
              ? delta.toStringAsFixed(0)
              : delta.toStringAsFixed(2))
          : '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
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
              controller: _nameController,
              label: 'Modifier name',
              hint: 'e.g. Extra Cheese, No Onion',
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              controller: _priceController,
              label: 'Price change',
              hint: '0.00 — use negative for removals',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Use negative values for removals (e.g. −0.50 for "No Cheese").',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
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
    final name = _nameController.text.trim();
    final priceDelta = double.tryParse(_priceController.text.trim());
    if (name.isEmpty || priceDelta == null) return;

    Navigator.of(context).pop(
      ModifierFormResult(name: name, priceDelta: priceDelta),
    );
  }
}

String previewModifierPriceDelta(double priceDelta) =>
    formatModifierPriceDelta(priceDelta);
