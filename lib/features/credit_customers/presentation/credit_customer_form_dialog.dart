import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/credit_customer.dart';

class CreditCustomerFormResult {
  const CreditCustomerFormResult({
    required this.fullName,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postcode,
    this.notes,
    this.creditLimit,
    required this.isActive,
    this.clearPhone = false,
    this.clearCreditLimit = false,
  });

  final String fullName;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postcode;
  final String? notes;
  final double? creditLimit;
  final bool isActive;
  final bool clearPhone;
  final bool clearCreditLimit;
}

class CreditCustomerFormDialog extends StatefulWidget {
  const CreditCustomerFormDialog({
    super.key,
    this.customer,
    this.title = 'Add Credit Customer',
  });

  final CreditCustomer? customer;
  final String title;

  static Future<CreditCustomerFormResult?> show(
    BuildContext context, {
    CreditCustomer? customer,
    String title = 'Add Credit Customer',
  }) {
    return showDialog<CreditCustomerFormResult>(
      context: context,
      builder: (context) =>
          CreditCustomerFormDialog(customer: customer, title: title),
    );
  }

  @override
  State<CreditCustomerFormDialog> createState() =>
      _CreditCustomerFormDialogState();
}

class _CreditCustomerFormDialogState extends State<CreditCustomerFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _address1Controller;
  late final TextEditingController _address2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _notesController;
  late final TextEditingController _creditLimitController;
  late bool _isActive;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _nameController = TextEditingController(text: customer?.fullName ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _address1Controller =
        TextEditingController(text: customer?.addressLine1 ?? '');
    _address2Controller =
        TextEditingController(text: customer?.addressLine2 ?? '');
    _cityController = TextEditingController(text: customer?.city ?? '');
    _postcodeController = TextEditingController(text: customer?.postcode ?? '');
    _notesController = TextEditingController(text: customer?.notes ?? '');
    _creditLimitController = TextEditingController(
      text: customer?.creditLimit?.toString() ?? '',
    );
    _isActive = customer?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _notesController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name',
                controller: _nameController,
              ),
              SizedBox(height: spacing.md),
              AppTextField(
                label: 'Phone',
                controller: _phoneController,
              ),
              SizedBox(height: spacing.md),
              AppTextField(
                label: 'Address line 1',
                controller: _address1Controller,
              ),
              SizedBox(height: spacing.md),
              AppTextField(
                label: 'Address line 2',
                controller: _address2Controller,
              ),
              SizedBox(height: spacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'City',
                      controller: _cityController,
                    ),
                  ),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Postcode',
                      controller: _postcodeController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.md),
              AppTextField(
                label: 'Credit limit (optional)',
                controller: _creditLimitController,
                hint: 'Leave empty for no limit',
              ),
              SizedBox(height: spacing.md),
              AppTextField(
                label: 'Notes',
                controller: _notesController,
                maxLines: 3,
              ),
              SizedBox(height: spacing.md),
              AppDropdown<bool>(
                label: 'Status',
                value: _isActive,
                items: const [true, false],
                itemLabel: (value) => value ? 'Active' : 'Inactive',
                onChanged: (value) {
                  if (value != null) setState(() => _isActive = value);
                },
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: spacing.md),
                Text(
                  _errorMessage!,
                  style: typography.bodySmall.copyWith(
                    color: context.appColors.error,
                  ),
                ),
              ],
            ],
          ),
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
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Name is required');
      return;
    }

    double? creditLimit;
    final limitText = _creditLimitController.text.trim();
    if (limitText.isNotEmpty) {
      creditLimit = double.tryParse(limitText);
      if (creditLimit == null || creditLimit < 0) {
        setState(() => _errorMessage = 'Enter a valid credit limit');
        return;
      }
    }

    Navigator.of(context).pop(
      CreditCustomerFormResult(
        fullName: name,
        phone: _nullableText(_phoneController.text),
        addressLine1: _nullableText(_address1Controller.text),
        addressLine2: _nullableText(_address2Controller.text),
        city: _nullableText(_cityController.text),
        postcode: _nullableText(_postcodeController.text),
        notes: _nullableText(_notesController.text),
        creditLimit: creditLimit,
        isActive: _isActive,
        clearPhone: _phoneController.text.trim().isEmpty,
        clearCreditLimit: limitText.isEmpty,
      ),
    );
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
