import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/order_held_badge.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/remote/supabase_service.dart';
import '../../../data/services/order_number_service.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/services/order_lifecycle.dart';
import '../../../domain/services/tablet_order_detection.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../orders/presentation/mark_paid_dialog.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../settings/providers/currency_providers.dart';
import '../providers/tablet_order_providers.dart';

/// Live order board: waiter tablets | customer app | all with mark-paid.
class TabletOrdersScreen extends ConsumerWidget {
  const TabletOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final syncEnabled =
        EnvConfig.isSupabaseConfigured && SupabaseService.isInitialized;
    final allAsync = ref.watch(tabletOrderListProvider);
    final waiterAsync = ref.watch(waiterTabletOrderListProvider);
    final customerAsync = ref.watch(customerAppOrderListProvider);
    final arrivalState = ref.watch(tabletOrderArrivalControllerProvider);
    final localDeviceId = ref.watch(deviceIdProvider);

    ref.listen<AsyncValue<List<Order>>>(tabletOrderListProvider, (previous, next) {
      next.whenData((orders) {
        ref
            .read(tabletOrderArrivalControllerProvider.notifier)
            .reconcileSyncedOrders(orders);
      });
    });

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            syncEnabled
                ? 'Live board — in-house tablet orders, customer app orders, and a combined queue with mark paid'
                : 'Configure Supabase to receive live orders from tablets and the customer app',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.md),
          Expanded(
            child: allAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading live orders...',
              ),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load live orders',
                message: error.toString(),
              ),
              data: (allOrders) {
                final unpaid = allOrders
                    .where((order) => !order.paymentStatus.isSettled)
                    .toList();
                final waiterOrders = waiterAsync.valueOrNull
                        ?.where((order) => !order.paymentStatus.isSettled)
                        .toList() ??
                    unpaid
                        .where(
                          (order) => isWaiterTabletOrder(order, localDeviceId),
                        )
                        .toList();
                final customerOrders = customerAsync.valueOrNull
                        ?.where((order) => !order.paymentStatus.isSettled)
                        .toList() ??
                    unpaid.where(isCustomerAppOrder).toList();

                final syncedIds = allOrders.map((order) => order.id).toSet();
                final incoming = arrivalState.pending
                    .where((entry) => !syncedIds.contains(entry.orderId))
                    .toList();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _OrderColumn(
                        title: 'In-house',
                        subtitle: 'Waiter tablet',
                        icon: Icons.tablet_android_outlined,
                        emptyMessage: 'No unpaid in-house orders',
                        orders: waiterOrders,
                        incoming: incoming
                            .where(
                              (entry) =>
                                  !isCustomerAppOrderNumber(entry.orderNumber),
                            )
                            .toList(),
                        arrivalState: arrivalState,
                        showMarkPaid: false,
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: _OrderColumn(
                        title: 'Customer app',
                        subtitle: 'Online / mobile',
                        icon: Icons.smartphone_outlined,
                        emptyMessage: 'No unpaid customer orders',
                        orders: customerOrders,
                        incoming: incoming
                            .where(
                              (entry) =>
                                  isCustomerAppOrderNumber(entry.orderNumber),
                            )
                            .toList(),
                        arrivalState: arrivalState,
                        showMarkPaid: false,
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: _OrderColumn(
                        title: 'All orders',
                        subtitle: 'Mark paid here',
                        icon: Icons.payments_outlined,
                        emptyMessage: 'No unpaid live orders',
                        orders: allOrders
                            .where(
                              (order) => !order.paymentStatus.isSettled,
                            )
                            .toList(),
                        incoming: incoming,
                        arrivalState: arrivalState,
                        showMarkPaid: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderColumn extends ConsumerWidget {
  const _OrderColumn({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emptyMessage,
    required this.orders,
    required this.incoming,
    required this.arrivalState,
    required this.showMarkPaid,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String emptyMessage;
  final List<Order> orders;
  final List<PendingTabletOrder> incoming;
  final TabletOrderArrivalState arrivalState;
  final bool showMarkPaid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final totalCount = incoming.length + orders.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              children: [
                Icon(icon, color: colors.secondary, size: spacing.lg),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: typography.titleMedium),
                      Text(
                        subtitle,
                        style: typography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountBadge(count: totalCount),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: totalCount == 0
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.md),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: typography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(spacing.sm),
                    itemCount: totalCount,
                    separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) {
                      if (index < incoming.length) {
                        return _IncomingOrderCard(
                          pending: incoming[index],
                          isHighlighted: arrivalState.highlightedOrderIds
                              .contains(incoming[index].orderId),
                        );
                      }
                      final order = orders[index - incoming.length];
                      return _LiveOrderCard(
                        order: order,
                        isHighlighted: arrivalState.highlightedOrderIds
                            .contains(order.id),
                        showMarkPaid: showMarkPaid,
                        onOpened: () => ref
                            .read(tabletOrderArrivalControllerProvider.notifier)
                            .acknowledgeHighlight(order.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spacing = context.appSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: Text(
          '$count',
          style: typography.labelMedium.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _IncomingOrderCard extends StatelessWidget {
  const _IncomingOrderCard({
    required this.pending,
    required this.isHighlighted,
  });

  final PendingTabletOrder pending;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Container(
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(
          color: isHighlighted ? colors.secondary : colors.border,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      padding: EdgeInsets.all(spacing.md),
      child: Row(
        children: [
          SizedBox(
            width: spacing.lg,
            height: spacing.lg,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.secondary,
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pending.orderNumber, style: typography.titleSmall),
                Text(
                  'Incoming · syncing…',
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveOrderCard extends ConsumerWidget {
  const _LiveOrderCard({
    required this.order,
    required this.isHighlighted,
    required this.showMarkPaid,
    required this.onOpened,
  });

  final Order order;
  final bool isHighlighted;
  final bool showMarkPaid;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatMoney = ref.watch(formatMoneyProvider);
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final role = ref.watch(currentUserProvider).role;
    final itemsAsync = ref.watch(orderItemsProvider(order.id));
    final canPay = OrderLifecycle.canMarkPaid(order, role);
    final isCancelled = order.status == OrderStatus.cancelled;
    final isHeld = order.isHeld;
    final sourceLabel = isCustomerAppOrder(order)
        ? 'Customer app'
        : 'In-house';

    return Material(
      color: isCancelled
          ? colors.errorContainer.withValues(alpha: 0.25)
          : isHeld
              ? colors.warning.withValues(alpha: 0.12)
              : isHighlighted
                  ? colors.secondaryContainer.withValues(alpha: 0.25)
                  : colors.surfaceVariant.withValues(alpha: 0.35),
      borderRadius: context.appRadius.mdBorder,
      child: InkWell(
        borderRadius: context.appRadius.mdBorder,
        onTap: () {
          onOpened();
          context.go('/orders/${order.id}');
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: context.appRadius.mdBorder,
            border: Border.all(
              color: isHighlighted
                  ? colors.secondary
                  : isCancelled
                      ? colors.error.withValues(alpha: 0.4)
                      : colors.border,
              width: isHighlighted ? 2 : 1,
            ),
          ),
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: typography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (isHighlighted)
                    _Chip(
                      label: 'New',
                      emphasized: true,
                      accent: colors.secondary,
                      onAccent: colors.onSecondary,
                    ),
                ],
              ),
              SizedBox(height: spacing.xs),
              Text(
                '$sourceLabel · ${order.orderType.label}',
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                DateFormat.MMMd().add_jm().format(order.createdAt),
                style: typography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (isHeld) ...[
                SizedBox(height: spacing.xs),
                const OrderHeldBadge(compact: true),
              ],
              SizedBox(height: spacing.sm),
              itemsAsync.when(
                loading: () => Text(
                  'Loading items…',
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                error: (_, __) => Text(
                  'Items unavailable',
                  style: typography.bodySmall.copyWith(color: colors.error),
                ),
                data: (items) => _OrderItemsSummary(
                  items: items,
                  formatMoney: formatMoney,
                ),
              ),
              SizedBox(height: spacing.sm),
              Row(
                children: [
                  _Chip(label: order.status.label, emphasized: true),
                  SizedBox(width: spacing.xs),
                  _Chip(label: order.paymentStatus.label),
                  const Spacer(),
                  Text(
                    formatMoney(order.total),
                    style: typography.titleSmall.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              if (showMarkPaid) ...[
                SizedBox(height: spacing.sm),
                if (canPay)
                  AppButton(
                    label: 'Mark paid',
                    size: AppButtonSize.small,
                    expand: true,
                    onPressed: () => _markPaid(context, ref),
                  )
                else if (order.paymentType == PaymentType.credit)
                  _Chip(label: 'On credit — settle in Credit Customers')
                else if (order.paymentStatus.isSettled)
                  _Chip(
                    label: 'Paid',
                    emphasized: true,
                    accent: colors.secondary,
                    onAccent: colors.onSecondary,
                  )
                else
                  _Chip(label: 'Payment locked until served'),
              ],
            ],
          ),
        ),
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
      if (!context.mounted) return;
      AppSnackbar.success(context, 'Order marked paid');
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.toString());
    }
  }
}

class _OrderItemsSummary extends StatelessWidget {
  const _OrderItemsSummary({
    required this.items,
    required this.formatMoney,
  });

  final List<OrderItem> items;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    if (items.isEmpty) {
      return Text(
        'No items',
        style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
      );
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}× ${item.name}'
                    '${item.variantName == null || item.variantName!.isEmpty ? '' : ' (${item.variantName})'}',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Text(
                  formatMoney(item.lineTotal),
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.emphasized = false,
    this.accent,
    this.onAccent,
  });

  final String label;
  final bool emphasized;
  final Color? accent;
  final Color? onAccent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spacing = context.appSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? (accent ?? colors.primaryContainer)
            : colors.surfaceVariant,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: Text(
          label,
          style: typography.labelSmall.copyWith(
            color: emphasized
                ? (onAccent ?? colors.onPrimaryContainer)
                : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
