import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/employee.dart';

class EmployeeFormResult {
  const EmployeeFormResult({
    required this.fullName,
    required this.role,
    this.phone,
    required this.hireDate,
    required this.payType,
    this.hourlyRate,
    this.monthlySalaryBase,
    required this.isActive,
    this.clearPhone = false,
  });

  final String fullName;
  final String role;
  final String? phone;
  final DateTime hireDate;
  final EmployeePayType payType;
  final double? hourlyRate;
  final double? monthlySalaryBase;
  final bool isActive;
  final bool clearPhone;
}

class EmployeeFormDialog extends StatefulWidget {
  const EmployeeFormDialog({
    super.key,
    this.employee,
    this.title = 'Add Employee',
  });

  final Employee? employee;
  final String title;

  static Future<EmployeeFormResult?> show(
    BuildContext context, {
    Employee? employee,
    String title = 'Add Employee',
  }) {
    return showDialog<EmployeeFormResult>(
      context: context,
      builder: (context) => EmployeeFormDialog(employee: employee, title: title),
    );
  }

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _roleController;
  late final TextEditingController _phoneController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _monthlySalaryController;
  late EmployeePayType _payType;
  late DateTime _hireDate;
  late bool _isActive;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _fullNameController = TextEditingController(text: employee?.fullName ?? '');
    _roleController = TextEditingController(text: employee?.role ?? '');
    _phoneController = TextEditingController(text: employee?.phone ?? '');
    _hourlyRateController = TextEditingController(
      text: employee?.hourlyRate?.toString() ?? '',
    );
    _monthlySalaryController = TextEditingController(
      text: employee?.monthlySalaryBase?.toString() ?? '',
    );
    _payType = employee?.payType ?? EmployeePayType.hourly;
    _hireDate = employee?.hireDate ?? DateTime.now();
    _isActive = employee?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    _monthlySalaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final dateFormat = DateFormat.yMMMd();

    return AlertDialog(
      title: Text(
        widget.title,
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: spacing.xxl * 6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _fullNameController,
                label: 'Full name',
                hint: 'e.g. Sara Ahmed',
              ),
              SizedBox(height: spacing.md),
              AppTextField(
                controller: _roleController,
                label: 'Job role',
                hint: 'e.g. Waiter, Chef',
              ),
              SizedBox(height: spacing.md),
              AppTextField(
                controller: _phoneController,
                label: 'Phone',
                hint: 'Optional',
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: spacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hire date',
                  style: typography.labelLarge.copyWith(color: colors.onSurface),
                ),
              ),
              SizedBox(height: spacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: dateFormat.format(_hireDate),
                  variant: AppButtonVariant.secondary,
                  onPressed: _pickHireDate,
                ),
              ),
              SizedBox(height: spacing.md),
              AppDropdown<EmployeePayType>(
                label: 'Pay type',
                value: _payType,
                items: EmployeePayType.values,
                itemLabel: (value) => value.label,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _payType = value);
                },
              ),
              SizedBox(height: spacing.md),
              if (_payType == EmployeePayType.hourly)
                AppTextField(
                  controller: _hourlyRateController,
                  label: 'Hourly rate',
                  hint: 'e.g. 12.50',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                )
              else
                AppTextField(
                  controller: _monthlySalaryController,
                  label: 'Monthly salary base',
                  hint: 'e.g. 45000',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              SizedBox(height: spacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Active',
                  style: typography.bodyMedium.copyWith(color: colors.onSurface),
                ),
                subtitle: Text(
                  'Inactive employees stay in records but are hidden from active-only views',
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: spacing.sm),
                Text(
                  _errorMessage!,
                  style: typography.bodySmall.copyWith(color: colors.error),
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

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _hireDate = picked);
    }
  }

  void _submit() {
    final fullName = _fullNameController.text.trim();
    final role = _roleController.text.trim();
    if (fullName.isEmpty || role.isEmpty) {
      setState(() => _errorMessage = 'Full name and job role are required');
      return;
    }

    final phoneText = _phoneController.text.trim();
    final hourlyRate = _payType == EmployeePayType.hourly
        ? double.tryParse(_hourlyRateController.text.trim())
        : null;
    final monthlySalaryBase = _payType == EmployeePayType.monthly
        ? double.tryParse(_monthlySalaryController.text.trim())
        : null;

    final payError = validateEmployeePay(
      payType: _payType,
      hourlyRate: hourlyRate,
      monthlySalaryBase: monthlySalaryBase,
    );
    if (payError != null) {
      setState(() => _errorMessage = payError);
      return;
    }

    Navigator.of(context).pop(
      EmployeeFormResult(
        fullName: fullName,
        role: role,
        phone: phoneText.isEmpty ? null : phoneText,
        hireDate: _hireDate,
        payType: _payType,
        hourlyRate: hourlyRate,
        monthlySalaryBase: monthlySalaryBase,
        isActive: _isActive,
        clearPhone: phoneText.isEmpty && widget.employee != null,
      ),
    );
  }
}
