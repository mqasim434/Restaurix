import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/order_enums.dart';

class RecordPaymentResult {
  const RecordPaymentResult({
    required this.amount,
    required this.paymentType,
    this.notes,
  });

  final double amount;
  final PaymentType paymentType;
  final String? notes;
}

class RecordPaymentDialog extends StatefulWidget {
  const RecordPaymentDialog({
    super.key,
    required this.customerName,
    required this.currentBalance,
  });

  final String customerName;
  final double currentBalance;

  static Future<RecordPaymentResult?> show(
    BuildContext context, {
    required String customerName,
    required double currentBalance,
  }) {
    return showDialog<RecordPaymentResult>(
      context: context,
      builder: (context) => RecordPaymentDialog(
        customerName: customerName,
        currentBalance: currentBalance,
      ),
    );
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  PaymentType _paymentType = PaymentType.cash;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final settlementTypes = PaymentType.values
        .where((type) => !type.isCreditAccount)
        .toList();

    return AlertDialog(
      title: const Text('Record payment'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.customerName,
              style: typography.titleSmall,
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Outstanding balance will be reduced by the payment amount.',
              style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              label: 'Amount',
              controller: _amountController,
            ),
            SizedBox(height: spacing.md),
            Text('Payment method', style: typography.labelMedium),
            SizedBox(height: spacing.xs),
            Wrap(
              spacing: spacing.xs,
              children: [
                for (final type in settlementTypes)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _paymentType == type,
                    onSelected: (_) => setState(() => _paymentType = type),
                  ),
              ],
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              label: 'Notes (optional)',
              controller: _notesController,
              maxLines: 2,
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: spacing.md),
              Text(
                _errorMessage!,
                style: typography.bodySmall.copyWith(color: colors.error),
              ),
            ],
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
          label: 'Record payment',
          onPressed: _submit,
        ),
      ],
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid payment amount');
      return;
    }
    if (amount > widget.currentBalance) {
      setState(
        () => _errorMessage =
            'Payment cannot exceed outstanding balance (${widget.currentBalance.toStringAsFixed(2)})',
      );
      return;
    }

    Navigator.of(context).pop(
      RecordPaymentResult(
        amount: amount,
        paymentType: _paymentType,
        notes: _nullableText(_notesController.text),
      ),
    );
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
