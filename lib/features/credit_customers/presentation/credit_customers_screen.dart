import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/credit_customer.dart';
import '../../settings/providers/currency_providers.dart';
import '../providers/credit_customer_providers.dart';
import 'credit_customer_form_dialog.dart';

class CreditCustomersScreen extends ConsumerWidget {
  const CreditCustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final customersAsync = ref.watch(filteredCreditCustomersProvider);
    final activeFilter = ref.watch(creditCustomerActiveFilterProvider);
    final formatMoney = ref.watch(formatMoneyProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Regular customers on account — orders from the tablet add to their balance; settle anytime.',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppButton(
                label: 'Add Customer',
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
                  hint: 'Name, phone, or address',
                  onChanged: (value) {
                    ref.read(creditCustomerSearchQueryProvider.notifier).state =
                        value;
                  },
                ),
              ),
              SizedBox(width: spacing.md),
              SizedBox(
                width: 220,
                child: AppDropdown<CreditCustomerActiveFilter>(
                  label: 'Filter',
                  value: activeFilter,
                  items: CreditCustomerActiveFilter.values,
                  itemLabel: (value) => value.label,
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(creditCustomerActiveFilterProvider.notifier)
                          .state = value;
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: customersAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading credit customers...',
              ),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load customers',
                message: error.toString(),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return AppEmptyState(
                    title: 'No credit customers found',
                    message: 'Add regulars who order on account and pay later.',
                    actionLabel: 'Add Customer',
                    onAction: () => _openForm(context, ref),
                  );
                }

                return AppDataTable<CreditCustomer>(
                  columns: [
                    AppDataColumn(
                      label: 'Name',
                      flex: 2,
                      cellBuilder: (_, customer) => Text(customer.fullName),
                    ),
                    AppDataColumn(
                      label: 'Phone',
                      flex: 2,
                      cellBuilder: (_, customer) =>
                          Text(customer.phone ?? '—'),
                    ),
                    AppDataColumn(
                      label: 'Balance',
                      cellBuilder: (_, customer) => Text(
                        formatMoney(customer.balance),
                        style: customer.hasOutstandingBalance
                            ? TextStyle(
                                color: colors.error,
                                fontWeight: FontWeight.w600,
                              )
                            : null,
                      ),
                    ),
                    AppDataColumn(
                      label: 'Status',
                      cellBuilder: (_, customer) =>
                          Text(customer.isActive ? 'Active' : 'Inactive'),
                    ),
                    AppDataColumn(
                      label: 'Actions',
                      flex: 3,
                      cellBuilder: (context, customer) {
                        return Wrap(
                          spacing: spacing.xs,
                          children: [
                            AppButton(
                              label: 'View',
                              size: AppButtonSize.small,
                              variant: AppButtonVariant.ghost,
                              onPressed: () => context.go(
                                '/credit-customers/${customer.id}',
                              ),
                            ),
                            AppButton(
                              label: 'Edit',
                              size: AppButtonSize.small,
                              variant: AppButtonVariant.ghost,
                              onPressed: () =>
                                  _openForm(context, ref, customer: customer),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  rows: customers,
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
    CreditCustomer? customer,
  }) async {
    final result = await CreditCustomerFormDialog.show(
      context,
      customer: customer,
      title: customer == null ? 'Add Credit Customer' : 'Edit Credit Customer',
    );
    if (result == null || !context.mounted) return;

    final notifier = ref.read(creditCustomerListProvider.notifier);
    final mutation = customer == null
        ? await notifier.create(
            fullName: result.fullName,
            phone: result.phone,
            addressLine1: result.addressLine1,
            addressLine2: result.addressLine2,
            city: result.city,
            postcode: result.postcode,
            notes: result.notes,
            creditLimit: result.creditLimit,
            isActive: result.isActive,
          )
        : await notifier.updateCustomer(
            customer.copyWith(
              fullName: result.fullName,
              phone: result.clearPhone ? null : result.phone,
              addressLine1: result.addressLine1,
              addressLine2: result.addressLine2,
              city: result.city,
              postcode: result.postcode,
              notes: result.notes,
              creditLimit:
                  result.clearCreditLimit ? null : result.creditLimit,
              isActive: result.isActive,
            ),
          );

    if (!context.mounted) return;
    if (mutation.success) {
      AppSnackbar.success(context, customer == null ? 'Customer added' : 'Customer updated');
    } else {
      AppSnackbar.error(context, mutation.errorMessage ?? 'Save failed');
    }
  }
}
