import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/models/reports.dart';
import '../../sales/presentation/sales_overview_panel.dart';
import '../providers/reports_providers.dart';
import 'widgets/date_range_selector_bar.dart';
import 'widgets/report_panels.dart';

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final filter = ref.watch(reportsFilterProvider);
    final range = filter.resolve();
    final snapshotAsync = ref.watch(reportsSnapshotProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Offline reports computed from local order data',
            style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: spacing.md),
          DateRangeSelectorBar(
            filter: filter,
            rangeLabel: salesDateRangeLabel(range),
            onPresetSelected: (preset) {
              ref.read(reportsFilterProvider.notifier).state =
                  filter.copyWith(preset: preset, clearCustomDates: true);
            },
            onCustomRangeSelected: (start, end) {
              ref.read(reportsFilterProvider.notifier).state =
                  ReportsFilterState(
                preset: SalesDateRangePreset.custom,
                customStart: start,
                customEnd: end,
                trendGranularity: filter.trendGranularity,
                topN: filter.topN,
                reportType: filter.reportType,
              );
            },
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 240,
                  child: _ReportNavList(
                    selected: filter.reportType,
                    onSelected: (type) {
                      ref.read(reportsFilterProvider.notifier).state =
                          filter.copyWith(reportType: type);
                    },
                  ),
                ),
                SizedBox(width: spacing.lg),
                Expanded(
                  child: snapshotAsync.when(
                    loading: () => const AppLoadingIndicator(
                      message: 'Loading reports...',
                    ),
                    error: (error, _) => AppEmptyState(
                      title: 'Failed to load reports',
                      message: error.toString(),
                    ),
                    data: (ReportsSnapshot snapshot) => _ReportContent(
                      filter: filter,
                      snapshot: snapshot,
                      onGranularityChanged: (granularity) {
                        ref.read(reportsFilterProvider.notifier).state =
                            filter.copyWith(trendGranularity: granularity);
                      },
                      onTopNChanged: (topN) {
                        ref.read(reportsFilterProvider.notifier).state =
                            filter.copyWith(topN: topN);
                      },
                    ),
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

class _ReportNavList extends StatelessWidget {
  const _ReportNavList({
    required this.selected,
    required this.onSelected,
  });

  final ReportType selected;
  final ValueChanged<ReportType> onSelected;

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
      child: ListView(
        children: [
          for (final type in ReportType.values)
            ListTile(
              selected: selected == type,
              selectedTileColor: colors.primaryContainer.withValues(alpha: 0.35),
              title: Text(
                type.label,
                style: typography.bodyMedium.copyWith(
                  color: selected == type
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                ),
              ),
              onTap: () => onSelected(type),
            ),
          SizedBox(height: spacing.sm),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.filter,
    required this.snapshot,
    required this.onGranularityChanged,
    required this.onTopNChanged,
  });

  final ReportsFilterState filter;
  final ReportsSnapshot snapshot;
  final ValueChanged<TrendGranularity> onGranularityChanged;
  final ValueChanged<int> onTopNChanged;

  @override
  Widget build(BuildContext context) {
    if (filter.reportType != ReportType.salesOverview &&
        filter.reportType != ReportType.cancelledOrders &&
        snapshot.isEmpty) {
      return const AppEmptyState(
        title: 'No data in this range',
        message: 'Try a wider date range or place orders from POS.',
      );
    }

    return switch (filter.reportType) {
      ReportType.salesOverview => const SalesOverviewPanel(),
      ReportType.salesTrend => SalesTrendPanel(
          buckets: snapshot.salesTrend,
          granularity: filter.trendGranularity,
          onGranularityChanged: onGranularityChanged,
        ),
      ReportType.dealsSales => DealsSalesPanel(rows: snapshot.dealsSales),
      ReportType.discounts => DiscountReportPanel(report: snapshot.discountReport),
      ReportType.cancelledOrders =>
        CancelledOrdersPanel(report: snapshot.cancelledOrders),
      ReportType.kitchenPerformance =>
        KitchenPerformancePanel(rows: snapshot.kitchenPerformance),
      ReportType.peakHours => PeakHoursPanel(rows: snapshot.peakHours),
      ReportType.aovTrend => AovTrendPanel(
          buckets: snapshot.aovTrend,
          granularity: filter.trendGranularity,
          onGranularityChanged: onGranularityChanged,
        ),
      ReportType.mostProducts => ProductRankingPanel(
          title: 'Most ordered products',
          subtitle: 'Top sellers by quantity in the selected range.',
          rows: snapshot.mostProducts,
          topN: filter.topN,
          onTopNChanged: onTopNChanged,
        ),
      ReportType.leastProducts => ProductRankingPanel(
          title: 'Least ordered products',
          subtitle:
              'Products sold in the range with the lowest volume. '
              'Products with zero sales are excluded.',
          rows: snapshot.leastProducts,
          topN: filter.topN,
          onTopNChanged: onTopNChanged,
        ),
    };
  }
}
