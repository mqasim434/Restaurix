import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/models/discount.dart';

class DiscountFormDialog extends StatefulWidget {
  const DiscountFormDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.initialType = DiscountType.percentage,
    this.initialValue,
    this.initialReason,
  });

  final String title;
  final String? subtitle;
  final DiscountType initialType;
  final double? initialValue;
  final String? initialReason;

  static Future<AppliedDiscountConfig?> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    DiscountType initialType = DiscountType.percentage,
    double? initialValue,
    String? initialReason,
  }) {
    return showDialog<AppliedDiscountConfig>(
      context: context,
      builder: (context) => DiscountFormDialog(
        title: title,
        subtitle: subtitle,
        initialType: initialType,
        initialValue: initialValue,
        initialReason: initialReason,
      ),
    );
  }

  @override
  State<DiscountFormDialog> createState() => _DiscountFormDialogState();
}

class AppliedDiscountConfig {
  const AppliedDiscountConfig({
    required this.type,
    required this.value,
    this.reason,
  });

  final DiscountType type;
  final double value;
  final String? reason;
}

class _DiscountFormDialogState extends State<DiscountFormDialog> {
  late DiscountType _type;
  late final TextEditingController _valueController;
  late final TextEditingController _reasonController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _valueController = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
    _reasonController = TextEditingController(text: widget.initialReason ?? '');
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return AlertDialog(
      title: Text(
        widget.title,
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: typography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.md),
            ],
            SegmentedButton<DiscountType>(
              segments: const [
                ButtonSegment(
                  value: DiscountType.percentage,
                  label: Text('%'),
                ),
                ButtonSegment(
                  value: DiscountType.fixed,
                  label: Text('Fixed'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() => _type = selection.first);
              },
            ),
            SizedBox(height: spacing.md),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: _type == DiscountType.percentage
                    ? 'Percentage (0–100)'
                    : 'Fixed amount',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: spacing.md),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
          label: 'Apply',
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
    final parsed = double.tryParse(_valueController.text.trim());
    if (parsed == null || parsed <= 0) {
      setState(() => _errorText = 'Enter a value greater than zero');
      return;
    }

    if (_type == DiscountType.percentage && parsed > 100) {
      setState(() => _errorText = 'Percentage cannot exceed 100');
      return;
    }

    final reason = _reasonController.text.trim();

    Navigator.of(context).pop(
      AppliedDiscountConfig(
        type: _type,
        value: parsed,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }
}
