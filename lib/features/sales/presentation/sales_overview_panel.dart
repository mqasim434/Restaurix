import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/sales_analytics.dart';
import '../../reports/providers/reports_providers.dart';

class SalesOverviewPanel extends ConsumerStatefulWidget {
  const SalesOverviewPanel({super.key});

  @override
  ConsumerState<SalesOverviewPanel> createState() => _SalesOverviewPanelState();
}

class _SalesOverviewPanelState extends ConsumerState<SalesOverviewPanel>
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
    final analyticsAsync = ref.watch(salesAnalyticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sales overview',
          style: context.appTypography.titleLarge,
        ),
        SizedBox(height: context.appSpacing.xs),
        Text(
          'Module 22 revenue slices for the selected date range.',
          style: context.appTypography.bodyMedium.copyWith(
            color: context.appColors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.appSpacing.md),
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
        SizedBox(height: context.appSpacing.md),
        Expanded(
          child: analyticsAsync.when(
            loading: () =>
                const AppLoadingIndicator(message: 'Loading sales data...'),
            error: (error, _) => AppEmptyState(
              title: 'Failed to load sales',
              message: error.toString(),
            ),
            data: (SalesAnalyticsSnapshot snapshot) {
              if (snapshot.isEmpty) {
                return const AppEmptyState(
                  title: 'No sales in this range',
                  message: 'Try a wider date range or place orders from POS.',
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _OverallTab(summary: snapshot.overall),
                  _ProductSalesTab(rows: snapshot.products),
                  _CategorySalesTab(rows: snapshot.categories),
                  _PaymentMethodTab(rows: snapshot.paymentMethods),
                  _EmployeeSalesTab(rows: snapshot.employees),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OverallTab extends StatelessWidget {
  const _OverallTab({required this.summary});

  final OverallSalesSummary summary;

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
              value: _formatCurrency(summary.netRevenue),
              subtitle: 'After discounts',
            ),
            _StatCard(
              title: 'Gross sales',
              value: _formatCurrency(summary.grossRevenue),
              subtitle: 'Before discounts',
            ),
            _StatCard(
              title: 'Discounts given',
              value: _formatCurrency(summary.totalDiscounts),
            ),
            _StatCard(
              title: 'Orders',
              value: '${summary.orderCount}',
            ),
            _StatCard(
              title: 'Average order',
              value: _formatCurrency(summary.averageOrderValue),
            ),
            _StatCard(
              title: 'Cancelled',
              value: '${summary.cancelledOrderCount}',
              subtitle: 'Excluded from revenue',
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        Text('By order type', style: context.appTypography.titleMedium),
        SizedBox(height: spacing.sm),
        AppDataTable<OrderTypeSalesBreakdown>(
          columns: [
            AppDataColumn(
              label: 'Type',
              cellBuilder: (_, row) => Text(row.orderType.label),
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
                _formatCurrency(row.netRevenue),
                textAlign: TextAlign.end,
              ),
            ),
            AppDataColumn(
              label: 'Gross sales',
              flex: 2,
              alignment: Alignment.centerRight,
              cellBuilder: (_, row) => Text(
                _formatCurrency(row.grossRevenue),
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
  const _ProductSalesTab({required this.rows});

  final List<ProductSalesRow> rows;

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
                  _formatCurrency(row.revenue),
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
  const _CategorySalesTab({required this.rows});

  final List<CategorySalesRow> rows;

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
            _formatCurrency(row.revenue),
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
  const _PaymentMethodTab({required this.rows});

  final List<PaymentMethodSalesRow> rows;

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
            _formatCurrency(row.netRevenue),
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
  const _EmployeeSalesTab({required this.rows});

  final List<EmployeeSalesRow> rows;

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
                  _formatCurrency(row.netRevenue),
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

String _formatCurrency(double amount) {
  return NumberFormat.simpleCurrency().format(amount);
}
