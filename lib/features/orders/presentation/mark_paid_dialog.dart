import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/models/order_enums.dart';

class MarkPaidDialog extends StatefulWidget {
  const MarkPaidDialog({
    super.key,
    this.initialPaymentType,
  });

  final PaymentType? initialPaymentType;

  static Future<PaymentType?> show(
    BuildContext context, {
    PaymentType? initialPaymentType,
  }) {
    return showDialog<PaymentType>(
      context: context,
      builder: (context) =>
          MarkPaidDialog(initialPaymentType: initialPaymentType),
    );
  }

  @override
  State<MarkPaidDialog> createState() => _MarkPaidDialogState();
}

class _MarkPaidDialogState extends State<MarkPaidDialog> {
  late PaymentType _paymentType;

  @override
  void initState() {
    super.initState();
    _paymentType = widget.initialPaymentType ?? PaymentType.cash;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return AlertDialog(
      title: Text(
        'Mark order paid',
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select the final payment type for this order.',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: PaymentType.values
                .where((type) => !type.isCreditAccount)
                .map((type) {
              return ChoiceChip(
                label: Text(type.label),
                selected: _paymentType == type,
                onSelected: (_) => setState(() => _paymentType = type),
              );
            }).toList(),
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
          label: 'Confirm',
          onPressed: () => Navigator.of(context).pop(_paymentType),
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
