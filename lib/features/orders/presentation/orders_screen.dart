import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/order_held_badge.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/services/order_lifecycle.dart';
import '../../settings/providers/currency_providers.dart';
import '../providers/order_management_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final filter = ref.watch(ordersListFilterProvider);
    final ordersAsync = ref.watch(filteredOrderListProvider);
    final formatMoney = ref.watch(formatMoneyProvider);
    final range = filter.resolve();
    final rangeLabel = _ordersRangeLabel(filter, range);

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
          SizedBox(height: spacing.md),
          _OrdersFilterBar(
            filter: filter,
            rangeLabel: rangeLabel,
            onPresetSelected: (preset) {
              ref.read(ordersListFilterProvider.notifier).state =
                  filter.copyWith(
                preset: preset,
                selectedDay: preset == SalesDateRangePreset.today
                    ? DateTime.now()
                    : filter.selectedDay,
                clearCustom: preset != SalesDateRangePreset.custom,
              );
            },
            onCustomRangeSelected: (start, end) {
              ref.read(ordersListFilterProvider.notifier).state =
                  filter.copyWith(
                preset: SalesDateRangePreset.custom,
                customStart: start,
                customEnd: end,
              );
            },
            onPreviousDay: () {
              ref.read(ordersListFilterProvider.notifier).state =
                  filter.copyWith(
                preset: SalesDateRangePreset.today,
                selectedDay: startOfLocalDay(filter.selectedDay)
                    .subtract(const Duration(days: 1)),
              );
            },
            onNextDay: filter.canGoNextDay
                ? () {
                    ref.read(ordersListFilterProvider.notifier).state =
                        filter.copyWith(
                      preset: SalesDateRangePreset.today,
                      selectedDay: startOfLocalDay(filter.selectedDay)
                          .add(const Duration(days: 1)),
                    );
                  }
                : null,
          ),
          SizedBox(height: spacing.md),
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
                  return AppEmptyState(
                    title: 'No orders for this period',
                    message:
                        'Try another date, or place orders from POS / Live Orders.',
                  );
                }

                final totalSales = orders.fold<double>(
                  0,
                  (sum, order) =>
                      order.status == OrderStatus.cancelled
                          ? sum
                          : sum + order.total,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${orders.length} order${orders.length == 1 ? '' : 's'}'
                      ' · ${formatMoney(totalSales)} (excl. cancelled)',
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    Expanded(
                      child: AppDataTable<Order>(
                        rows: orders,
                        emptyMessage: 'No orders for this period',
                        onRowTap: (order) =>
                            context.go('/orders/${order.id}'),
                        columns: [
                          AppDataColumn(
                            label: 'Order #',
                            flex: 2,
                            cellBuilder: (context, order) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: typography.titleSmall.copyWith(
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (order.isHeld) ...[
                                    SizedBox(height: spacing.xs),
                                    const OrderHeldBadge(compact: true),
                                  ],
                                ],
                              );
                            },
                          ),
                          AppDataColumn(
                            label: 'Date / Time',
                            flex: 2,
                            cellBuilder: (_, order) => Text(
                              DateFormat.yMMMd()
                                  .add_jm()
                                  .format(order.createdAt),
                              style: typography.bodySmall.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          AppDataColumn(
                            label: 'Type',
                            cellBuilder: (_, order) =>
                                Text(order.orderType.label),
                          ),
                          AppDataColumn(
                            label: 'Status',
                            flex: 2,
                            cellBuilder: (context, order) => _StatusChip(
                              label: order.status.label,
                              emphasized: true,
                              cancelled:
                                  order.status == OrderStatus.cancelled,
                            ),
                          ),
                          AppDataColumn(
                            label: 'Payment',
                            flex: 2,
                            cellBuilder: (context, order) => _StatusChip(
                              label: order.paymentStatus.label,
                            ),
                          ),
                          AppDataColumn(
                            label: 'Total',
                            alignment: Alignment.centerRight,
                            cellBuilder: (_, order) => Text(
                              formatMoney(order.total),
                              style: typography.titleSmall.copyWith(
                                color: order.status == OrderStatus.cancelled
                                    ? colors.onSurfaceVariant
                                    : colors.primary,
                                decoration:
                                    order.status == OrderStatus.cancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                            ),
                          ),
                        ],
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

String _ordersRangeLabel(OrdersListFilter filter, SalesDateRange range) {
  if (filter.preset == SalesDateRangePreset.today) {
    final day = filter.selectedDay;
    if (filter.isBrowsingToday) return 'Today';
    return DateFormat.yMMMEd().format(day);
  }
  return salesDateRangeLabel(range);
}

class _OrdersFilterBar extends StatelessWidget {
  const _OrdersFilterBar({
    required this.filter,
    required this.rangeLabel,
    required this.onPresetSelected,
    required this.onCustomRangeSelected,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final OrdersListFilter filter;
  final String rangeLabel;
  final ValueChanged<SalesDateRangePreset> onPresetSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeSelected;
  final VoidCallback onPreviousDay;
  final VoidCallback? onNextDay;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final showDayNav = filter.preset == SalesDateRangePreset.today;

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RangeChip(
          label: 'Today',
          selected: filter.preset == SalesDateRangePreset.today,
          onTap: () => onPresetSelected(SalesDateRangePreset.today),
        ),
        _RangeChip(
          label: 'This week',
          selected: filter.preset == SalesDateRangePreset.thisWeek,
          onTap: () => onPresetSelected(SalesDateRangePreset.thisWeek),
        ),
        _RangeChip(
          label: 'This month',
          selected: filter.preset == SalesDateRangePreset.thisMonth,
          onTap: () => onPresetSelected(SalesDateRangePreset.thisMonth),
        ),
        _RangeChip(
          label: 'Custom',
          selected: filter.preset == SalesDateRangePreset.custom,
          onTap: () => _pickCustomRange(context),
        ),
        if (showDayNav) ...[
          SizedBox(width: spacing.xs),
          _DayNavigator(
            label: rangeLabel,
            onPrevious: onPreviousDay,
            onNext: onNextDay,
          ),
        ] else
          Text(
            rangeLabel,
            style: context.appTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = filter.customStart ?? now;
    final initialEnd = filter.customEnd ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (picked != null) {
      onCustomRangeSelected(picked.start, picked.end);
    }
  }
}

class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.sm),
            child: Text(
              label,
              style: typography.labelLarge.copyWith(color: colors.onSurface),
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceVariant,
      borderRadius: radius.fullBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius.fullBorder,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSpacing.md,
            vertical: context.appSpacing.xs,
          ),
          child: Text(
            label,
            style: context.appTypography.labelLarge.copyWith(
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.emphasized = false,
    this.cancelled = false,
  });

  final String label;
  final bool emphasized;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    final background = cancelled
        ? colors.errorContainer.withValues(alpha: 0.5)
        : emphasized
            ? colors.primaryContainer
            : colors.surfaceVariant;
    final foreground = cancelled
        ? colors.error
        : emphasized
            ? colors.onPrimaryContainer
            : colors.onSurfaceVariant;

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: context.appRadius.smBorder,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSpacing.sm,
            vertical: context.appSpacing.xs,
          ),
          child: Text(
            label,
            style: typography.labelSmall.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}
