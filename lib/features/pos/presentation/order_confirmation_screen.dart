import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/models/order_enums.dart';
import '../../orders/providers/order_management_providers.dart';
import 'pos_cart_panel.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: orderAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (order) {
          if (order == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order not found',
                    style: typography.titleMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  AppButton(
                    label: 'Back to POS',
                    onPressed: () => context.go('/sales'),
                  ),
                ],
              ),
            );
          }

          return itemsAsync.when(
            loading: () => const Center(child: AppLoadingIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (items) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: context.appRadius.mdBorder,
                      border: Border.all(color: colors.border),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(spacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.success,
                                color: colors.success,
                                size: 32,
                              ),
                              SizedBox(width: spacing.sm),
                              Expanded(
                                child: Text(
                                  'Order placed',
                                  style: typography.headlineSmall.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing.md),
                          Text(
                            order.orderNumber,
                            style: typography.titleLarge.copyWith(
                              color: colors.primary,
                            ),
                          ),
                          SizedBox(height: spacing.sm),
                          Text(
                            '${order.orderType.label} · ${order.paymentStatus.name.toUpperCase()} · ${order.status.name}',
                            style: typography.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (order.isPrepaid)
                            Padding(
                              padding: EdgeInsets.only(top: spacing.xs),
                              child: Text(
                                'Prepaid — payment recorded on placement',
                                style: typography.bodySmall.copyWith(
                                  color: colors.success,
                                ),
                              ),
                            ),
                          Divider(height: spacing.lg, color: colors.divider),
                          for (final item in items)
                            Padding(
                              padding: EdgeInsets.only(bottom: spacing.sm),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.name}',
                                      style: typography.bodyMedium.copyWith(
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatPosPrice(item.lineTotal),
                                    style: typography.bodyMedium.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Divider(height: spacing.lg, color: colors.divider),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total',
                                  style: typography.titleMedium.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                formatPosPrice(order.total),
                                style: typography.titleLarge.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing.lg),
                          AppButton(
                            label: 'New sale',
                            expand: true,
                            onPressed: () => context.go('/sales'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
