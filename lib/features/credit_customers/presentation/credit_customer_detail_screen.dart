import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/credit_customer.dart';
import '../../../domain/models/credit_transaction.dart';
import '../../settings/providers/currency_providers.dart';
import '../providers/credit_customer_providers.dart';
import 'record_payment_dialog.dart';

class CreditCustomerDetailScreen extends ConsumerWidget {
  const CreditCustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final formatMoney = ref.watch(formatMoneyProvider);
    final customerAsync = ref.watch(creditCustomerByIdProvider(customerId));
    final transactionsAsync =
        ref.watch(creditCustomerTransactionsProvider(customerId));

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: customerAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading customer...'),
        error: (error, _) => AppEmptyState(
          title: 'Failed to load customer',
          message: error.toString(),
        ),
        data: (customer) {
          if (customer == null) {
            return AppEmptyState(
              title: 'Customer not found',
              message: 'This credit account may have been removed.',
              actionLabel: 'Back to list',
              onAction: () => context.go('/credit-customers'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppButton(
                    label: 'Back',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.go('/credit-customers'),
                  ),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.fullName, style: typography.titleLarge),
                        if (customer.phone != null)
                          Text(
                            customer.phone!,
                            style: typography.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        if (customer.displayAddress.isNotEmpty)
                          Text(
                            customer.displayAddress,
                            style: typography.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Outstanding balance', style: typography.labelMedium),
                      Text(
                        formatMoney(customer.balance),
                        style: typography.headlineSmall.copyWith(
                          color: customer.hasOutstandingBalance
                              ? colors.error
                              : colors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: spacing.md),
                  AppButton(
                    label: 'Record payment',
                    onPressed: customer.balance <= 0
                        ? null
                        : () => _recordPayment(context, ref, customer),
                  ),
                ],
              ),
              if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                SizedBox(height: spacing.md),
                Text(
                  customer.notes!,
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: spacing.lg),
              Text('Transaction history', style: typography.titleMedium),
              SizedBox(height: spacing.md),
              Expanded(
                child: transactionsAsync.when(
                  loading: () => const AppLoadingIndicator(
                    message: 'Loading transactions...',
                  ),
                  error: (error, _) => AppEmptyState(
                    title: 'Failed to load transactions',
                    message: error.toString(),
                  ),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const AppEmptyState(
                        title: 'No transactions yet',
                        message:
                            'Charges appear when this customer places on-account orders from the tablet.',
                      );
                    }

                    return AppDataTable<CreditTransaction>(
                      columns: [
                        AppDataColumn(
                          label: 'Date',
                          flex: 2,
                          cellBuilder: (_, tx) => Text(
                            DateFormat.yMMMd().add_jm().format(tx.createdAt),
                          ),
                        ),
                        AppDataColumn(
                          label: 'Type',
                          flex: 2,
                          cellBuilder: (_, tx) => Text(tx.transactionType.label),
                        ),
                        AppDataColumn(
                          label: 'Amount',
                          cellBuilder: (_, tx) => Text(
                            _formatSignedAmount(tx, formatMoney),
                            style: TextStyle(
                              color: tx.increasesBalance
                                  ? colors.error
                                  : colors.primary,
                            ),
                          ),
                        ),
                        AppDataColumn(
                          label: 'Balance after',
                          cellBuilder: (_, tx) =>
                              Text(formatMoney(tx.balanceAfter)),
                        ),
                        AppDataColumn(
                          label: 'Notes',
                          flex: 2,
                          cellBuilder: (_, tx) => Text(tx.notes ?? '—'),
                        ),
                      ],
                      rows: transactions,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatSignedAmount(
    CreditTransaction transaction,
    String Function(double) formatMoney,
  ) {
    final prefix = transaction.increasesBalance ? '+' : '-';
    return '$prefix${formatMoney(transaction.amount)}';
  }

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    CreditCustomer customer,
  ) async {
    final result = await RecordPaymentDialog.show(
      context,
      customerName: customer.fullName,
      currentBalance: customer.balance,
    );
    if (result == null || !context.mounted) return;

    final mutation = await ref
        .read(creditPaymentControllerProvider.notifier)
        .recordPayment(
          creditCustomerId: customer.id,
          amount: result.amount,
          paymentType: result.paymentType,
          notes: result.notes,
        );

    if (!context.mounted) return;
    if (mutation.success) {
      AppSnackbar.success(context, 'Payment recorded');
      ref.invalidate(creditCustomerByIdProvider(customerId));
    } else {
      AppSnackbar.error(context, mutation.errorMessage ?? 'Payment failed');
    }
  }
}
