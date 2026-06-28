import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/employee.dart';
import '../providers/employee_providers.dart';
import 'employee_form_dialog.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final employeesAsync = ref.watch(filteredEmployeesProvider);
    final activeFilter = ref.watch(employeeActiveFilterProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Employee records for attendance, salary, and future POS accounts',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppButton(
                label: 'Add Employee',
                icon: AppIcons.add,
                onPressed: () => _openForm(context, ref),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: 'Search',
                  hint: 'Name, role, or phone',
                  onChanged: (value) {
                    ref.read(employeeSearchQueryProvider.notifier).state =
                        value;
                  },
                ),
              ),
              SizedBox(width: spacing.md),
              SizedBox(
                width: 180,
                child: AppDropdown<EmployeeActiveFilter>(
                  label: 'Status',
                  value: activeFilter,
                  items: EmployeeActiveFilter.values,
                  itemLabel: (value) => value.label,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(employeeActiveFilterProvider.notifier).state =
                          value;
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: employeesAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading employees...'),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load employees',
                message: error.toString(),
              ),
              data: (employees) {
                if (employees.isEmpty) {
                  return AppEmptyState(
                    title: 'No employees found',
                    message: activeFilter == EmployeeActiveFilter.all
                        ? 'Add your first employee record.'
                        : 'Try changing the status filter or search query.',
                    actionLabel: 'Add Employee',
                    onAction: () => _openForm(context, ref),
                  );
                }

                return AppDataTable<Employee>(
                  columns: [
                    AppDataColumn(
                      label: 'Name',
                      flex: 2,
                      cellBuilder: (_, employee) => Text(employee.fullName),
                    ),
                    AppDataColumn(
                      label: 'Role',
                      flex: 2,
                      cellBuilder: (_, employee) => Text(employee.role),
                    ),
                    AppDataColumn(
                      label: 'Pay',
                      flex: 2,
                      cellBuilder: (_, employee) => Text(
                        _formatPay(employee),
                      ),
                    ),
                    AppDataColumn(
                      label: 'Hired',
                      cellBuilder: (_, employee) => Text(
                        DateFormat.yMMMd().format(employee.hireDate),
                      ),
                    ),
                    AppDataColumn(
                      label: 'Status',
                      cellBuilder: (_, employee) => Text(
                        employee.isActive ? 'Active' : 'Inactive',
                      ),
                    ),
                    AppDataColumn(
                      label: 'Actions',
                      flex: 2,
                      cellBuilder: (context, employee) {
                        return Wrap(
                          spacing: spacing.xs,
                          children: [
                            AppButton(
                              label: 'Edit',
                              size: AppButtonSize.small,
                              variant: AppButtonVariant.ghost,
                              onPressed: () =>
                                  _openForm(context, ref, employee: employee),
                            ),
                            AppButton(
                              label: employee.isActive ? 'Deactivate' : 'Activate',
                              size: AppButtonSize.small,
                              variant: AppButtonVariant.secondary,
                              onPressed: () =>
                                  _toggleActive(context, ref, employee),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  rows: employees,
                  emptyMessage: 'No employees found',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Employee? employee,
  }) async {
    final result = await EmployeeFormDialog.show(
      context,
      employee: employee,
      title: employee == null ? 'Add Employee' : 'Edit Employee',
    );
    if (result == null || !context.mounted) return;

    final notifier = ref.read(employeeListProvider.notifier);
    final EmployeeMutationResult mutation;

    if (employee == null) {
      mutation = await notifier.create(
        fullName: result.fullName,
        role: result.role,
        hireDate: result.hireDate,
        payType: result.payType,
        phone: result.phone,
        hourlyRate: result.hourlyRate,
        monthlySalaryBase: result.monthlySalaryBase,
        isActive: result.isActive,
      );
    } else {
      mutation = await notifier.updateEmployee(
        employee.copyWith(
          fullName: result.fullName,
          role: result.role,
          phone: result.phone,
          clearPhone: result.clearPhone,
          hireDate: result.hireDate,
          payType: result.payType,
          hourlyRate: result.hourlyRate,
          clearHourlyRate: result.payType != EmployeePayType.hourly,
          monthlySalaryBase: result.monthlySalaryBase,
          clearMonthlySalaryBase: result.payType != EmployeePayType.monthly,
          isActive: result.isActive,
        ),
      );
    }

    if (!context.mounted) return;
    _showMutationFeedback(context, mutation);
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    final activating = !employee.isActive;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: activating ? 'Activate employee?' : 'Deactivate employee?',
      content: Text(
        activating
            ? 'Show "${employee.fullName}" in active-only views again.'
            : 'Deactivate "${employee.fullName}"? Historical attendance and sales records are preserved.',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: activating ? 'Activate' : 'Deactivate',
    );

    if (confirmed != true || !context.mounted) return;

    final mutation = await ref.read(employeeListProvider.notifier).setActive(
          employee: employee,
          isActive: activating,
        );

    if (!context.mounted) return;
    _showMutationFeedback(context, mutation);
  }

  void _showMutationFeedback(
    BuildContext context,
    EmployeeMutationResult mutation,
  ) {
    if (mutation.success) {
      AppSnackbar.success(context, 'Employee saved');
      return;
    }

    AppSnackbar.error(
      context,
      mutation.errorMessage ?? 'Could not save employee',
    );
  }
}

String _formatPay(Employee employee) {
  final currency = NumberFormat.simpleCurrency();
  return switch (employee.payType) {
    EmployeePayType.hourly =>
      '${currency.format(employee.hourlyRate ?? 0)}/hr',
    EmployeePayType.monthly =>
      '${currency.format(employee.monthlySalaryBase ?? 0)}/mo',
  };
}
