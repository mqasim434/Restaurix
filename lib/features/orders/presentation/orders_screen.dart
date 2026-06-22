import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/order_held_badge.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/services/order_lifecycle.dart';
import '../providers/order_management_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final ordersAsync = ref.watch(orderListProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Track order status, edit unpaid orders, and manage cancellations',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: ordersAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading orders...'),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load orders',
                message: error.toString(),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return const AppEmptyState(
                    title: 'No orders yet',
                    message: 'Placed orders from POS will appear here.',
                  );
                }

                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                  itemBuilder: (context, index) {
                    return _OrderListTile(order: orders[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderListTile extends StatelessWidget {
  const _OrderListTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final isCancelled = order.status == OrderStatus.cancelled;
    final isHeld = order.isHeld;

    return Material(
      color: isCancelled
          ? colors.errorContainer.withValues(alpha: 0.25)
          : isHeld
              ? colors.warning.withValues(alpha: 0.12)
              : colors.surface,
      borderRadius: context.appRadius.mdBorder,
      child: InkWell(
        borderRadius: context.appRadius.mdBorder,
        onTap: () => context.go('/orders/${order.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: context.appRadius.mdBorder,
            border: Border.all(
              color: isCancelled
                  ? colors.error.withValues(alpha: 0.4)
                  : isHeld
                      ? colors.warning.withValues(alpha: 0.5)
                      : colors.border,
            ),
          ),
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: typography.titleMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      '${order.orderType.label} · ${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (isHeld) ...[
                      SizedBox(height: spacing.xs),
                      const OrderHeldBadge(compact: true),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(label: order.status.label, emphasized: true),
                  SizedBox(height: spacing.xs),
                  _StatusChip(label: order.paymentStatus.label),
                  SizedBox(height: spacing.xs),
                  Text(
                    NumberFormat.simpleCurrency().format(order.total),
                    style: typography.titleSmall.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.emphasized = false});

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
            color: emphasized ? colors.onPrimaryContainer : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
