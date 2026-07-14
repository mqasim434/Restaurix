import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../domain/models/discount.dart';
import '../../../../domain/models/reports.dart';
import '../../../settings/providers/currency_providers.dart';
import 'simple_bar_chart.dart';

class ReportPanelScaffold extends StatelessWidget {
  const ReportPanelScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.toolbar,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? toolbar;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: typography.titleLarge),
        SizedBox(height: spacing.xs),
        Text(
          subtitle,
          style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
        if (toolbar != null) ...[
          SizedBox(height: spacing.md),
          toolbar!,
        ],
        SizedBox(height: spacing.md),
        Expanded(child: child),
      ],
    );
  }
}

class SalesTrendPanel extends ConsumerWidget {
  const SalesTrendPanel({
    super.key,
    required this.buckets,
    required this.granularity,
    required this.onGranularityChanged,
  });

  final List<TrendBucket> buckets;
  final TrendGranularity granularity;
  final ValueChanged<TrendGranularity> onGranularityChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatMoney = ref.watch(formatMoneyProvider);

    return ReportPanelScaffold(
      title: 'Sales trend',
      subtitle: 'Net revenue over time (cancelled orders excluded).',
      toolbar: _GranularityPicker(
        value: granularity,
        onChanged: onGranularityChanged,
      ),
      child: ListView(
        children: [
          AppCard(
            child: CompactBarChart(
              values: buckets.map((bucket) => bucket.netRevenue).toList(),
              labels: buckets.map((bucket) => bucket.label).toList(),
            ),
          ),
          SizedBox(height: context.appSpacing.md),
          AppDataTable<TrendBucket>(
            columns: [
              AppDataColumn(
                label: 'Period',
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
            rows: buckets,
            emptyMessage: 'No sales in range',
          ),
        ],
      ),
    );
  }
}

class DealsSalesPanel extends ConsumerWidget {
  const DealsSalesPanel({super.key, required this.rows});

  final List<DealSalesRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatMoney = ref.watch(formatMoneyProvider);

    return ReportPanelScaffold(
      title: 'Deals sales',
      subtitle: 'Deal lines sold in the selected range.',
      child: AppDataTable<DealSalesRow>(
        columns: [
          AppDataColumn(
            label: 'Deal',
            flex: 3,
            cellBuilder: (_, row) => Text(row.name),
          ),
          AppDataColumn(
            label: 'Qty',
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
        emptyMessage: 'No deal sales in range',
      ),
    );
  }
}

class DiscountReportPanel extends ConsumerWidget {
  const DiscountReportPanel({super.key, required this.report});

  final DiscountReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final formatMoney = ref.watch(formatMoneyProvider);

    return ReportPanelScaffold(
      title: 'Discount report',
      subtitle: 'Discounts applied on non-cancelled orders.',
      child: ListView(
        children: [
          _StatCard(
            title: 'Total discount given',
            value: formatMoney(report.totalDiscount),
          ),
          SizedBox(height: spacing.md),
          Text('By scope', style: context.appTypography.titleMedium),
          SizedBox(height: spacing.sm),
          AppDataTable<DiscountScopeRow>(
            columns: [
              AppDataColumn(
                label: 'Scope',
                cellBuilder: (_, row) => Text(_scopeLabel(row.scope)),
              ),
              AppDataColumn(
                label: 'Count',
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) =>
                    Text('${row.count}', textAlign: TextAlign.end),
              ),
              AppDataColumn(
                label: 'Amount',
                flex: 2,
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) => Text(
                  formatMoney(row.amount),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            rows: report.byScope,
            emptyMessage: 'No discounts in range',
          ),
          SizedBox(height: spacing.lg),
          Text('Details', style: context.appTypography.titleMedium),
          SizedBox(height: spacing.sm),
          AppDataTable<DiscountDetailRow>(
            columns: [
              AppDataColumn(
                label: 'Scope',
                cellBuilder: (_, row) => Text(_scopeLabel(row.scope)),
              ),
              AppDataColumn(
                label: 'Type',
                cellBuilder: (_, row) => Text(row.type.name),
              ),
              AppDataColumn(
                label: 'Reason',
                flex: 2,
                cellBuilder: (_, row) => Text(row.reason),
              ),
              AppDataColumn(
                label: 'Amount',
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) => Text(
                  formatMoney(row.amount),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            rows: report.details,
            emptyMessage: 'No discount details in range',
          ),
        ],
      ),
    );
  }
}

class CancelledOrdersPanel extends ConsumerWidget {
  const CancelledOrdersPanel({super.key, required this.report});

  final CancelledOrdersReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final formatMoney = ref.watch(formatMoneyProvider);

    return ReportPanelScaffold(
      title: 'Cancelled orders',
      subtitle: 'Operational cancellations in the selected range.',
      child: ListView(
        children: [
          Wrap(
            spacing: spacing.md,
            runSpacing: spacing.md,
            children: [
              _StatCard(
                title: 'Cancelled orders',
                value: '${report.cancelledCount}',
              ),
              _StatCard(
                title: 'Value if not cancelled',
                value: formatMoney(report.forfeitedValue),
                subtitle: 'Sum of cancelled order totals',
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Text('Top reasons', style: context.appTypography.titleMedium),
          SizedBox(height: spacing.sm),
          AppDataTable<CancellationReasonRow>(
            columns: [
              AppDataColumn(
                label: 'Reason',
                flex: 3,
                cellBuilder: (_, row) => Text(row.reason),
              ),
              AppDataColumn(
                label: 'Count',
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) =>
                    Text('${row.count}', textAlign: TextAlign.end),
              ),
            ],
            rows: report.topReasons,
            emptyMessage: 'No cancellations in range',
          ),
        ],
      ),
    );
  }
}

class KitchenPerformancePanel extends StatelessWidget {
  const KitchenPerformancePanel({super.key, required this.rows});

  final List<KitchenPerformanceRow> rows;

  @override
  Widget build(BuildContext context) {
    return ReportPanelScaffold(
      title: 'Kitchen performance',
      subtitle:
          'Average minutes from received to ready per kitchen category. '
          'Items without ready timestamps show N/A.',
      child: AppDataTable<KitchenPerformanceRow>(
        columns: [
          AppDataColumn(
            label: 'Kitchen category',
            flex: 2,
            cellBuilder: (_, row) => Text(row.category),
          ),
          AppDataColumn(
            label: 'Samples',
            alignment: Alignment.centerRight,
            cellBuilder: (_, row) =>
                Text('${row.sampleCount}', textAlign: TextAlign.end),
          ),
          AppDataColumn(
            label: 'Avg minutes',
            alignment: Alignment.centerRight,
            cellBuilder: (_, row) => Text(
              row.averageMinutes == null
                  ? 'N/A'
                  : row.averageMinutes!.toStringAsFixed(1),
              textAlign: TextAlign.end,
            ),
          ),
        ],
        rows: rows,
        emptyMessage: 'No kitchen timing data in range',
      ),
    );
  }
}

class PeakHoursPanel extends StatelessWidget {
  const PeakHoursPanel({super.key, required this.rows});

  final List<PeakHourRow> rows;

  @override
  Widget build(BuildContext context) {
    return ReportPanelScaffold(
      title: 'Peak hours',
      subtitle: 'Order volume by hour of day (device local time).',
      child: ListView(
        children: [
          AppCard(
            child: CompactBarChart(
              values: rows.map((row) => row.orderCount).toList(),
              labels: rows.map((row) => row.label).toList(),
              maxHeight: 240,
            ),
          ),
          SizedBox(height: context.appSpacing.md),
          AppDataTable<PeakHourRow>(
            columns: [
              AppDataColumn(label: 'Hour', cellBuilder: (_, row) => Text(row.label)),
              AppDataColumn(
                label: 'Orders',
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) =>
                    Text('${row.orderCount}', textAlign: TextAlign.end),
              ),
            ],
            rows: rows.where((row) => row.orderCount > 0).toList(),
            emptyMessage: 'No orders in range',
          ),
        ],
      ),
    );
  }
}

class AovTrendPanel extends ConsumerWidget {
  const AovTrendPanel({
    super.key,
    required this.buckets,
    required this.granularity,
    required this.onGranularityChanged,
  });

  final List<TrendBucket> buckets;
  final TrendGranularity granularity;
  final ValueChanged<TrendGranularity> onGranularityChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatMoney = ref.watch(formatMoneyProvider);

    return ReportPanelScaffold(
      title: 'Average order value',
      subtitle: 'Mean net order total per period.',
      toolbar: _GranularityPicker(
        value: granularity,
        onChanged: onGranularityChanged,
      ),
      child: ListView(
        children: [
          AppCard(
            child: CompactBarChart(
              values: buckets.map((bucket) => bucket.averageOrderValue).toList(),
              labels: buckets.map((bucket) => bucket.label).toList(),
            ),
          ),
          SizedBox(height: context.appSpacing.md),
          AppDataTable<TrendBucket>(
            columns: [
              AppDataColumn(
                label: 'Period',
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
                label: 'Average order',
                flex: 2,
                alignment: Alignment.centerRight,
                cellBuilder: (_, row) => Text(
                  formatMoney(row.averageOrderValue),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            rows: buckets,
            emptyMessage: 'No orders in range',
          ),
        ],
      ),
    );
  }
}

class ProductRankingPanel extends ConsumerWidget {
  const ProductRankingPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.topN,
    required this.onTopNChanged,
  });

  final String title;
  final String subtitle;
  final List<ProductRankingRow> rows;
  final int topN;
  final ValueChanged<int> onTopNChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatMoney = ref.watch(formatMoneyProvider);

    return ReportPanelScaffold(
      title: title,
      subtitle: subtitle,
      toolbar: SizedBox(
        width: 140,
        child: AppDropdown<int>(
          label: 'Top N',
          value: topN,
          items: const [5, 10, 20, 50],
          itemLabel: (value) => '$value',
          onChanged: (value) {
            if (value != null) onTopNChanged(value);
          },
        ),
      ),
      child: AppDataTable<ProductRankingRow>(
        columns: [
          AppDataColumn(
            label: 'Product',
            flex: 3,
            cellBuilder: (_, row) => Text(row.name),
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
        emptyMessage: 'No qualifying product sales in range',
      ),
    );
  }
}

class _GranularityPicker extends StatelessWidget {
  const _GranularityPicker({
    required this.value,
    required this.onChanged,
  });

  final TrendGranularity value;
  final ValueChanged<TrendGranularity> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AppDropdown<TrendGranularity>(
        label: 'Granularity',
        value: value,
        items: TrendGranularity.values,
        itemLabel: (granularity) => granularity.name,
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
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
      width: 220,
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

String _scopeLabel(DiscountScope scope) {
  return switch (scope) {
    DiscountScope.item => 'Item',
    DiscountScope.category => 'Category',
    DiscountScope.wholeOrder => 'Whole order',
  };
}
