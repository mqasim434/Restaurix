import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class VariantFormResult {
  const VariantFormResult({
    required this.name,
    required this.price,
    required this.isDefault,
  });

  final String name;
  final double price;
  final bool isDefault;
}

class VariantFormDialog extends StatefulWidget {
  const VariantFormDialog({
    super.key,
    this.initialName,
    this.initialPrice,
    this.initialIsDefault = false,
    this.title = 'Add Variant',
  });

  final String? initialName;
  final double? initialPrice;
  final bool initialIsDefault;
  final String title;

  static Future<VariantFormResult?> show(
    BuildContext context, {
    String? initialName,
    double? initialPrice,
    bool initialIsDefault = false,
    String title = 'Add Variant',
  }) {
    return showDialog<VariantFormResult>(
      context: context,
      builder: (context) => VariantFormDialog(
        initialName: initialName,
        initialPrice: initialPrice,
        initialIsDefault: initialIsDefault,
        title: title,
      ),
    );
  }

  @override
  State<VariantFormDialog> createState() => _VariantFormDialogState();
}

class _VariantFormDialogState extends State<VariantFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _priceController = TextEditingController(
      text: widget.initialPrice?.toStringAsFixed(2) ?? '',
    );
    _isDefault = widget.initialIsDefault;
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
        width: spacing.xxl * 6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Variant name',
              hint: 'e.g. Large',
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              controller: _priceController,
              label: 'Price',
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: spacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Default variant',
                style: typography.bodyMedium.copyWith(color: colors.onSurface),
              ),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
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
    final price = double.tryParse(_priceController.text.trim());
    if (name.isEmpty || price == null || price < 0) return;

    Navigator.of(context).pop(
      VariantFormResult(name: name, price: price, isDefault: _isDefault),
    );
  }
}
