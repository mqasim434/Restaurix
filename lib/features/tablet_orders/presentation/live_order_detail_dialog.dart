import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/order_held_badge.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/services/order_lifecycle.dart';
import '../../../domain/services/tablet_order_detection.dart';
import '../../auth/providers/auth_providers.dart';
import '../../credit_customers/providers/credit_customer_providers.dart';
import '../../orders/presentation/cancel_order_dialog.dart';
import '../../orders/presentation/mark_paid_dialog.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../settings/providers/currency_providers.dart';

/// Popup order summary for Live Orders (no navigation to the Orders tab).
class LiveOrderDetailDialog extends ConsumerWidget {
  const LiveOrderDetailDialog({super.key, required this.orderId});

  final String orderId;

  static Future<void> show(
    BuildContext context, {
    required String orderId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => LiveOrderDetailDialog(orderId: orderId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTypography;

    return AlertDialog(
      title: orderAsync.maybeWhen(
        data: (order) => Text(
          order?.orderNumber ?? 'Order',
          style: typography.titleLarge.copyWith(color: colors.onSurface),
        ),
        orElse: () => Text(
          'Order',
          style: typography.titleLarge.copyWith(color: colors.onSurface),
        ),
      ),
      content: SizedBox(
        width: 520,
        child: orderAsync.when(
          loading: () => const SizedBox(
            height: 160,
            child: AppLoadingIndicator(message: 'Loading order...'),
          ),
          error: (error, _) => Text(
            error.toString(),
            style: typography.bodyMedium.copyWith(color: colors.error),
          ),
          data: (order) {
            if (order == null) {
              return Text(
                'Order not found',
                style: typography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              );
            }

            return itemsAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: AppLoadingIndicator(message: 'Loading items...'),
              ),
              error: (error, _) => Text(
                error.toString(),
                style: typography.bodyMedium.copyWith(color: colors.error),
              ),
              data: (items) => _LiveOrderDetailBody(
                order: order,
                items: items,
              ),
            );
          },
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        spacing.lg,
        0,
        spacing.lg,
        spacing.md,
      ),
      actions: [
        AppButton(
          label: 'Close',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _LiveOrderDetailBody extends ConsumerWidget {
  const _LiveOrderDetailBody({
    required this.order,
    required this.items,
  });

  final Order order;
  final List<OrderItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final formatMoney = ref.watch(formatMoneyProvider);
    final role = ref.watch(currentUserProvider).role;
    final canPay = OrderLifecycle.canMarkPaid(order, role);
    final canCompleteCredit =
        OrderLifecycle.canCompleteCreditOrder(order, role);
    final canCancel = OrderLifecycle.canCancel(order, role);
    final sourceLabel =
        isCustomerAppOrder(order) ? 'Customer app' : 'In-house';
    final creditCustomerName = order.creditCustomerId == null
        ? null
        : ref
            .watch(creditCustomerByIdProvider(order.creditCustomerId!))
            .maybeWhen(
              data: (customer) => customer?.fullName ?? 'Unknown customer',
              orElse: () => 'Loading...',
            );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.xs,
            children: [
              _MetaChip(label: sourceLabel),
              _MetaChip(label: order.orderType.label),
              _MetaChip(label: order.status.label, emphasized: true),
              _MetaChip(label: order.paymentStatus.label),
              if (order.isHeld) const OrderHeldBadge(compact: true),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            DateFormat.yMMMd().add_jm().format(order.createdAt),
            style: typography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            Text(
              'Notes: ${order.notes}',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (creditCustomerName != null) ...[
            SizedBox(height: spacing.sm),
            Text(
              'Credit account: $creditCustomerName',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (order.status == OrderStatus.cancelled &&
              order.cancelReason != null) ...[
            SizedBox(height: spacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.errorContainer.withValues(alpha: 0.35),
                borderRadius: context.appRadius.mdBorder,
                border: Border.all(color: colors.error),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.md),
                child: Text(
                  'Cancelled: ${order.cancelReason}',
                  style: typography.bodyMedium.copyWith(color: colors.error),
                ),
              ),
            ),
          ],
          SizedBox(height: spacing.md),
          Text(
            'Items',
            style: typography.titleSmall.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: spacing.sm),
          if (items.isEmpty)
            Text(
              'No items',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}× ${item.name}'
                        '${item.variantName == null || item.variantName!.isEmpty ? '' : ' (${item.variantName})'}',
                        style: typography.bodyMedium,
                      ),
                    ),
                    Text(
                      formatMoney(item.lineTotal),
                      style: typography.bodyMedium,
                    ),
                  ],
                ),
              ),
          Divider(height: spacing.lg, color: colors.divider),
          Row(
            children: [
              Text(
                'Total',
                style: typography.titleMedium.copyWith(color: colors.onSurface),
              ),
              const Spacer(),
              Text(
                formatMoney(order.total),
                style: typography.titleMedium.copyWith(color: colors.primary),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          if (canPay)
            AppButton(
              label: 'Mark paid',
              expand: true,
              onPressed: () => _markPaid(context, ref),
            ),
          if (canCompleteCredit)
            AppButton(
              label: 'Complete Order',
              expand: true,
              onPressed: () => _completeCreditOrder(context, ref),
            ),
          if ((canPay || canCompleteCredit) && canCancel)
            SizedBox(height: spacing.sm),
          if (canCancel)
            AppButton(
              label: 'Cancel order',
              variant: AppButtonVariant.danger,
              expand: true,
              onPressed: () => _cancelOrder(context, ref),
            ),
          if (canCompleteCredit) ...[
            SizedBox(height: spacing.sm),
            Text(
              'On credit — no payment now. Balance stays on the customer account.',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    final paymentType = await MarkPaidDialog.show(
      context,
      initialPaymentType: order.paymentType == PaymentType.credit
          ? PaymentType.cash
          : order.paymentType,
    );
    if (paymentType == null || !context.mounted) return;

    try {
      await ref.read(placeOrderProvider).markPaid(
            orderId: order.id,
            paymentType: paymentType,
          );
      ref.invalidate(orderDetailProvider(order.id));
      if (!context.mounted) return;
      AppSnackbar.success(context, 'Order marked paid and completed');
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.toString());
    }
  }

  Future<void> _completeCreditOrder(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref.read(placeOrderProvider).completeCreditOrder(
            orderId: order.id,
          );
      ref.invalidate(orderDetailProvider(order.id));
      if (!context.mounted) return;
      AppSnackbar.success(
        context,
        'Order completed — settle balance in Credit Customers',
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.toString());
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final result = await CancelOrderDialog.show(
      context,
      requiresRefundNote: order.paymentStatus.isSettled,
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(placeOrderProvider).cancel(
            orderId: order.id,
            reason: result.reason,
            refundNote: result.refundNote,
          );
      ref.invalidate(orderDetailProvider(order.id));
      if (!context.mounted) return;
      AppSnackbar.success(context, 'Order cancelled');
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.toString());
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? colors.primaryContainer : colors.surfaceVariant,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.appSpacing.sm,
          vertical: context.appSpacing.xs,
        ),
        child: Text(
          label,
          style: typography.labelSmall.copyWith(
            color: emphasized
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
