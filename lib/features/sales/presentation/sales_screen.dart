import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/sales_analytics.dart';
import '../../reports/providers/reports_providers.dart';
import '../../settings/providers/currency_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final filter = ref.watch(salesFilterProvider);
    final range = filter.resolve();
    final analyticsAsync = ref.watch(salesAnalyticsProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Revenue and order breakdowns from local order data',
            style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: spacing.md),
          _DateRangeSelector(
            filter: filter,
            rangeLabel: salesDateRangeLabel(range),
            onPresetSelected: (preset) {
              ref.read(salesFilterProvider.notifier).state =
                  filter.copyWith(preset: preset, clearCustomDates: true);
            },
            onCustomRangeSelected: (start, end) {
              ref.read(salesFilterProvider.notifier).state = SalesFilterState(
                preset: SalesDateRangePreset.custom,
                customStart: start,
                customEnd: end,
              );
            },
          ),
          SizedBox(height: spacing.md),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overall'),
              Tab(text: 'Products'),
              Tab(text: 'Categories'),
              Tab(text: 'Payment'),
              Tab(text: 'Employees'),
            ],
          ),
          SizedBox(height: spacing.md),
          Expanded(
            child: analyticsAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading sales data...'),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load sales',
                message: error.toString(),
              ),
              data: (snapshot) {
                if (snapshot.isEmpty) {
                  return AppEmptyState(
                    title: 'No sales in this range',
                    message:
                        'Try a wider date range or place orders from POS.',
                  );
                }

                final formatMoney = ref.watch(formatMoneyProvider);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _OverallTab(summary: snapshot.overall, formatMoney: formatMoney),
                    _ProductSalesTab(rows: snapshot.products, formatMoney: formatMoney),
                    _CategorySalesTab(rows: snapshot.categories, formatMoney: formatMoney),
                    _PaymentMethodTab(rows: snapshot.paymentMethods, formatMoney: formatMoney),
                    _EmployeeSalesTab(rows: snapshot.employees, formatMoney: formatMoney),
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

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.filter,
    required this.rangeLabel,
    required this.onPresetSelected,
    required this.onCustomRangeSelected,
  });

  final SalesFilterState filter;
  final String rangeLabel;
  final ValueChanged<SalesDateRangePreset> onPresetSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeSelected;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

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

class _OverallTab extends StatelessWidget {
  const _OverallTab({required this.summary, required this.formatMoney});

  final OverallSalesSummary summary;
  final MoneyFormatter formatMoney;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return ListView(
      children: [
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.md,
          children: [
            _StatCard(
              title: 'Net revenue',
              value: formatMoney(summary.netRevenue),
              subtitle: 'After discounts',
            ),
            _StatCard(
              title: 'Gross sales',
              value: formatMoney(summary.grossRevenue),
              subtitle: 'Before discounts',
            ),
            _StatCard(
              title: 'Discounts given',
              value: formatMoney(summary.totalDiscounts),
            ),
            _StatCard(
              title: 'Orders',
              value: '${summary.orderCount}',
            ),
            _StatCard(
              title: 'Average order',
              value: formatMoney(summary.averageOrderValue),
            ),
            _StatCard(
              title: 'Cancelled',
              value: '${summary.cancelledOrderCount}',
              subtitle: 'Excluded from revenue',
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        Text(
          'By order type',
          style: context.appTypography.titleMedium,
        ),
        SizedBox(height: spacing.sm),
        if (summary.byOrderType.isEmpty)
          Text(
            'No order-type breakdown available.',
            style: context.appTypography.bodyMedium.copyWith(
              color: context.appColors.onSurfaceVariant,
            ),
          )
        else
          AppDataTable<OrderTypeSalesBreakdown>(
            columns: [
              AppDataColumn(
                label: 'Type',
                cellBuilder: (_, row) => Text(row.orderType.label),
              ),
              AppDataColumn(
                label: 'Orders',
                flex: 1,
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) =>
                    Text('${row.orderCount}', textAlign: TextAlign.end),
              ),
              AppDataColumn(
                label: 'Net revenue',
                flex: 2,
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) => Text(
                  formatMoney(row.netRevenue),
                  textAlign: TextAlign.end,
                ),
              ),
              AppDataColumn(
                label: 'Gross sales',
                flex: 2,
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) => Text(
                  formatMoney(row.grossRevenue),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            rows: summary.byOrderType,
            emptyMessage: 'No orders in range',
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return SizedBox(
      width: 200,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: typography.labelLarge.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(value, style: typography.headlineSmall),
            if (subtitle != null) ...[
              SizedBox(height: spacing.xs),
              Text(
                subtitle!,
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ProductSortColumn { quantity, revenue }

class _ProductSalesTab extends StatefulWidget {
  const _ProductSalesTab({required this.rows, required this.formatMoney});

  final List<ProductSalesRow> rows;
  final MoneyFormatter formatMoney;

  @override
  State<_ProductSalesTab> createState() => _ProductSalesTabState();
}

class _ProductSalesTabState extends State<_ProductSalesTab> {
  _ProductSortColumn _sortColumn = _ProductSortColumn.revenue;
  bool _sortDescending = true;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.rows];
    sorted.sort((a, b) {
      final comparison = switch (_sortColumn) {
        _ProductSortColumn.quantity =>
          a.quantitySold.compareTo(b.quantitySold),
        _ProductSortColumn.revenue => a.revenue.compareTo(b.revenue),
      };
      return _sortDescending ? -comparison : comparison;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: context.appSpacing.sm,
          children: [
            AppButton(
              label: 'Sort by revenue',
              variant: _sortColumn == _ProductSortColumn.revenue
                  ? AppButtonVariant.primary
                  : AppButtonVariant.ghost,
              onPressed: () => setState(() {
                if (_sortColumn == _ProductSortColumn.revenue) {
                  _sortDescending = !_sortDescending;
                } else {
                  _sortColumn = _ProductSortColumn.revenue;
                  _sortDescending = true;
                }
              }),
            ),
            AppButton(
              label: 'Sort by quantity',
              variant: _sortColumn == _ProductSortColumn.quantity
                  ? AppButtonVariant.primary
                  : AppButtonVariant.ghost,
              onPressed: () => setState(() {
                if (_sortColumn == _ProductSortColumn.quantity) {
                  _sortDescending = !_sortDescending;
                } else {
                  _sortColumn = _ProductSortColumn.quantity;
                  _sortDescending = true;
                }
              }),
            ),
          ],
        ),
        SizedBox(height: context.appSpacing.md),
        Expanded(
          child: AppDataTable<ProductSalesRow>(
            columns: [
              AppDataColumn(
                label: 'Product / deal',
                flex: 3,
                cellBuilder: (_, row) => Text(
                  row.isDeal ? '${row.name} (Deal)' : row.name,
                ),
              ),
              AppDataColumn(
                label: 'Qty sold',
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) =>
                    Text('${row.quantitySold}', textAlign: TextAlign.end),
              ),
              AppDataColumn(
                label: 'Revenue',
                flex: 2,
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) => Text(
                  widget.formatMoney(row.revenue),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            rows: sorted,
            emptyMessage: 'No product sales in range',
          ),
        ),
      ],
    );
  }
}

class _CategorySalesTab extends StatelessWidget {
  const _CategorySalesTab({required this.rows, required this.formatMoney});

  final List<CategorySalesRow> rows;
  final MoneyFormatter formatMoney;

  @override
  Widget build(BuildContext context) {
    return AppDataTable<CategorySalesRow>(
      columns: [
        AppDataColumn(
          label: 'Category',
          flex: 3,
          cellBuilder: (_, row) => Text(row.categoryName),
        ),
        AppDataColumn(
          label: 'Qty sold',
          alignment: Alignment.centerRight,
          cellBuilder: (_, row) =>
              Text('${row.quantitySold}', textAlign: TextAlign.end),
        ),
        AppDataColumn(
          label: 'Revenue',
          flex: 2,
          alignment: Alignment.centerRight,
          cellBuilder: (_, row) => Text(
            formatMoney(row.revenue),
            textAlign: TextAlign.end,
          ),
        ),
      ],
      rows: rows,
      emptyMessage: 'No category sales in range',
    );
  }
}

class _PaymentMethodTab extends StatelessWidget {
  const _PaymentMethodTab({required this.rows, required this.formatMoney});

  final List<PaymentMethodSalesRow> rows;
  final MoneyFormatter formatMoney;

  @override
  Widget build(BuildContext context) {
    return AppDataTable<PaymentMethodSalesRow>(
      columns: [
        AppDataColumn(
          label: 'Payment method',
          flex: 2,
          cellBuilder: (_, row) => Text(row.label),
        ),
        AppDataColumn(
          label: 'Orders',
          alignment: Alignment.centerRight,
          cellBuilder: (_, row) =>
              Text('${row.orderCount}', textAlign: TextAlign.end),
        ),
        AppDataColumn(
          label: 'Net revenue',
          flex: 2,
          alignment: Alignment.centerRight,
          cellBuilder: (_, row) => Text(
            formatMoney(row.netRevenue),
            textAlign: TextAlign.end,
          ),
        ),
      ],
      rows: rows,
      emptyMessage: 'No payment data in range',
    );
  }
}

class _EmployeeSalesTab extends StatelessWidget {
  const _EmployeeSalesTab({required this.rows, required this.formatMoney});

  final List<EmployeeSalesRow> rows;
  final MoneyFormatter formatMoney;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spacing = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Linked to order creator IDs until employee records are available.',
          style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: spacing.md),
        Expanded(
          child: AppDataTable<EmployeeSalesRow>(
            columns: [
              AppDataColumn(
                label: 'Staff',
                flex: 2,
                cellBuilder: (_, row) => Text(row.displayName),
              ),
              AppDataColumn(
                label: 'Orders',
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) =>
                    Text('${row.orderCount}', textAlign: TextAlign.end),
              ),
              AppDataColumn(
                label: 'Net revenue',
                flex: 2,
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) => Text(
                  formatMoney(row.netRevenue),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            rows: rows,
            emptyMessage: 'No employee sales in range',
          ),
        ),
      ],
    );
  }
}
