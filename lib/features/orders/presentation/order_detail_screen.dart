import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../settings/providers/currency_providers.dart';
import '../../pos/providers/order_edit_provider.dart';
import '../../printing/providers/kitchen_ticket_providers.dart';
import '../../printing/providers/receipt_providers.dart';
import '../../printing/kitchen_ticket/kitchen_ticket_feedback.dart';
import '../../printing/receipt/receipt_feedback.dart';
import '../../credit_customers/providers/credit_customer_providers.dart';
import '../providers/order_management_providers.dart';
import 'cancel_order_dialog.dart';
import 'mark_paid_dialog.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    return orderAsync.when(
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (order) {
        if (order == null) {
          return Center(
            child: AppButton(
              label: 'Back to orders',
              onPressed: () => context.go('/orders'),
            ),
          );
        }

        return itemsAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (items) => _OrderDetailBody(order: order, items: items),
        );
      },
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.order, required this.items});

  final Order order;
  final List<OrderItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final actions = ref.watch(orderActionsProvider(order));
    final editBlocked = OrderLifecycle.editBlockedReason(order);
    final formatMoney = ref.watch(formatMoneyProvider);
    final creditCustomerName = order.creditCustomerId == null
        ? null
        : ref
            .watch(creditCustomerByIdProvider(order.creditCustomerId!))
            .maybeWhen(
              data: (customer) => customer?.fullName ?? 'Unknown customer',
              orElse: () => 'Loading...',
            );

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.ghost,
                        size: AppButtonSize.small,
                        onPressed: () => context.go('/orders'),
                      ),
                      SizedBox(width: spacing.sm),
                      Expanded(
                        child: Text(
                          order.orderNumber,
                          style: typography.headlineSmall.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  if (order.isHeld && order.status != OrderStatus.cancelled) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.15),
                        borderRadius: context.appRadius.mdBorder,
                        border: Border.all(color: colors.warning),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const OrderHeldBadge(),
                            SizedBox(height: spacing.xs),
                            Text(
                              'This order is temporarily set aside. Status remains ${order.status.label.toLowerCase()} and totals are unchanged.',
                              style: typography.bodySmall.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.md),
                  ],
                  if (order.status == OrderStatus.cancelled) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withValues(alpha: 0.35),
                        borderRadius: context.appRadius.mdBorder,
                        border: Border.all(color: colors.error),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cancelled',
                              style: typography.titleMedium.copyWith(
                                color: colors.error,
                              ),
                            ),
                            if (order.cancelReason != null) ...[
                              SizedBox(height: spacing.xs),
                              Text(
                                order.cancelReason!,
                                style: typography.bodyMedium,
                              ),
                            ],
                            if (order.cancelRefundNote != null) ...[
                              SizedBox(height: spacing.xs),
                              Text(
                                'Refund note: ${order.cancelRefundNote}',
                                style: typography.bodySmall.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.md),
                  ],
                  _InfoCard(
                    title: 'Summary',
                    rows: [
                      _InfoRow('Type', order.orderType.label),
                      _InfoRow('Status', order.status.label),
                      _InfoRow('Payment', order.paymentStatus.label),
                      if (order.paymentType != null)
                        _InfoRow('Payment type', order.paymentType!.label),
                      if (creditCustomerName != null)
                        _InfoRow('Credit account', creditCustomerName),
                      _InfoRow(
                        'Created',
                        DateFormat.yMMMd().add_jm().format(order.createdAt),
                      ),
                      if (order.notes != null)
                        _InfoRow('Notes', order.notes!),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  _InfoCard(
                    title: 'Items',
                    child: Column(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: EdgeInsets.only(bottom: spacing.sm),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x ${item.name}',
                                    style: typography.bodyMedium,
                                  ),
                                ),
                                Text(formatMoney(item.lineTotal)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (editBlocked != null &&
                      order.paymentStatus.isSettled) ...[
                    SizedBox(height: spacing.md),
                    Text(
                      editBlocked,
                      style: typography.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: spacing.lg),
          SizedBox(
            width: 300,
            child: _InfoCard(
              title: 'Totals & actions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoRow('Subtotal', formatMoney(order.subtotal)),
                  if (order.itemDiscountTotal > 0)
                    _InfoRow(
                      'Line discounts',
                      '-${formatMoney(order.itemDiscountTotal)}',
                    ),
                  if (order.orderDiscountTotal > 0)
                    _InfoRow(
                      'Order discount',
                      '-${formatMoney(order.orderDiscountTotal)}',
                    ),
                  Divider(height: spacing.lg, color: colors.divider),
                  _InfoRow('Total', formatMoney(order.total), bold: true),
                  SizedBox(height: spacing.lg),
                  if (order.status != OrderStatus.cancelled && items.isNotEmpty) ...[
                    AppButton(
                      label: 'Reprint Kitchen Copy',
                      variant: AppButtonVariant.secondary,
                      expand: true,
                      onPressed: () => _reprintKitchenCopy(context, ref),
                    ),
                    SizedBox(height: spacing.sm),
                    AppButton(
                      label: 'Reprint Receipt',
                      variant: AppButtonVariant.secondary,
                      expand: true,
                      onPressed: () => _reprintReceipt(context, ref),
                    ),
                    SizedBox(height: spacing.sm),
                  ],
                  for (final action in actions) ...[
                    AppButton(
                      label: action.label,
                      variant: action.type == OrderActionType.cancel
                          ? AppButtonVariant.danger
                          : action.type == OrderActionType.hold
                              ? AppButtonVariant.secondary
                              : action.type == OrderActionType.editInPos
                                  ? AppButtonVariant.secondary
                                  : AppButtonVariant.primary,
                      expand: true,
                      onPressed: () => _handleAction(context, ref, action),
                    ),
                    SizedBox(height: spacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    OrderAction action,
  ) async {
    final controller = ref.read(placeOrderProvider);

    try {
      switch (action.type) {
        case OrderActionType.editInPos:
          final blocked = OrderLifecycle.editBlockedReason(order);
          if (blocked != null) {
            AppSnackbar.error(context, blocked);
            return;
          }
          await ref.read(orderEditLoaderProvider).loadIntoPos(order.id);
          if (!context.mounted) return;
          context.go('/sales');
        case OrderActionType.advance:
          PaymentType? paymentType;
          if (action.nextStatus == OrderStatus.paid &&
              order.paymentType == null) {
            paymentType = await MarkPaidDialog.show(context);
            if (paymentType == null || !context.mounted) return;
          } else if (action.nextStatus == OrderStatus.paid) {
            paymentType = order.paymentType;
          }

          final markPaid = action.nextStatus == OrderStatus.paid;
          await controller.advance(
            orderId: order.id,
            targetStatus: action.nextStatus!,
            paymentType: paymentType,
          );
          ref.invalidate(orderDetailProvider(order.id));
          if (!context.mounted) return;
          if (markPaid) {
            await _printReceiptAfterPayment(context, ref);
          } else {
            AppSnackbar.success(context, '${action.label} succeeded');
          }
        case OrderActionType.markPaid:
          break;
        case OrderActionType.hold:
          await controller.setHeld(orderId: order.id, isHeld: true);
          ref.invalidate(orderDetailProvider(order.id));
          if (context.mounted) {
            AppSnackbar.success(context, 'Order held');
          }
        case OrderActionType.resume:
          await controller.setHeld(orderId: order.id, isHeld: false);
          ref.invalidate(orderDetailProvider(order.id));
          if (context.mounted) {
            AppSnackbar.success(context, 'Order resumed');
          }
        case OrderActionType.cancel:
          final result = await CancelOrderDialog.show(
            context,
            requiresRefundNote: order.paymentStatus.isSettled,
          );
          if (result == null || !context.mounted) return;

          await controller.cancel(
            orderId: order.id,
            reason: result.reason,
            refundNote: result.refundNote,
          );
          ref.invalidate(orderDetailProvider(order.id));
          if (context.mounted) {
            AppSnackbar.success(context, 'Order cancelled');
          }
      }
    } on OrderLifecycleException catch (error) {
      if (context.mounted) AppSnackbar.error(context, error.message);
    } catch (error) {
      if (context.mounted) {
        AppSnackbar.error(context, error.toString());
      }
    }
  }

  Future<void> _reprintKitchenCopy(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final result = await ref
          .read(kitchenTicketPrintControllerProvider)
          .printOrder(orderId: order.id, isReprint: true);
      if (!context.mounted) return;
      showKitchenPrintFeedback(
        context,
        result,
        successMessage: 'Kitchen copy reprinted',
      );
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, 'Kitchen reprint failed: $error');
    }
  }

  Future<void> _reprintReceipt(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final result = await ref
          .read(receiptPrintControllerProvider)
          .printOrder(orderId: order.id, isReprint: true);
      if (!context.mounted) return;
      showReceiptPrintFeedback(
        context,
        result,
        successMessage: 'Receipt reprinted',
      );
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, 'Receipt reprint failed: $error');
    }
  }

  Future<void> _printReceiptAfterPayment(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final result = await ref
          .read(receiptPrintControllerProvider)
          .printOrder(orderId: order.id, isReprint: false);
      if (!context.mounted) return;
      if (result.hasWarnings) {
        showReceiptPrintFeedback(context, result);
      } else {
        AppSnackbar.success(context, 'Marked paid and receipt printed');
      }
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.info(
        context,
        'Order marked paid, but receipt printing failed: $error',
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    this.rows = const [],
    this.child,
  });

  final String title;
  final List<_InfoRow> rows;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: typography.titleMedium.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            if (child != null) child!,
            for (final row in rows) row,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final style = bold ? typography.titleMedium : typography.bodyMedium;

    return Padding(
      padding: EdgeInsets.only(bottom: context.appSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style.copyWith(color: colors.onSurface),
            ),
          ),
          Text(
            value,
            style: style.copyWith(
              color: bold ? colors.primary : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
