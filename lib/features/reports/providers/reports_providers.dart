import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/navigation_provider.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/order_analytics_loader.dart';
import '../../../domain/models/reports.dart';
import '../../../domain/models/sales_analytics.dart';
import '../../../domain/services/reports_analytics.dart';
import '../../../domain/services/sales_analytics.dart';

final orderAnalyticsLoaderProvider = Provider<OrderAnalyticsLoader>((ref) {
  return OrderAnalyticsLoader(ref.watch(isarProvider));
});

class ReportsFilterState {
  const ReportsFilterState({
    this.preset = SalesDateRangePreset.today,
    this.customStart,
    this.customEnd,
    this.trendGranularity = TrendGranularity.daily,
    this.topN = 10,
    this.reportType = ReportType.salesOverview,
  });

  final SalesDateRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final TrendGranularity trendGranularity;
  final int topN;
  final ReportType reportType;

  SalesDateRange resolve({DateTime? now}) {
    return resolveSalesDateRange(
      preset: preset,
      customStart: customStart,
      customEnd: customEnd,
      now: now,
    );
  }

  ReportsFilterState copyWith({
    SalesDateRangePreset? preset,
    DateTime? customStart,
    DateTime? customEnd,
    TrendGranularity? trendGranularity,
    int? topN,
    ReportType? reportType,
    bool clearCustomDates = false,
  }) {
    return ReportsFilterState(
      preset: preset ?? this.preset,
      customStart: clearCustomDates ? null : (customStart ?? this.customStart),
      customEnd: clearCustomDates ? null : (customEnd ?? this.customEnd),
      trendGranularity: trendGranularity ?? this.trendGranularity,
      topN: topN ?? this.topN,
      reportType: reportType ?? this.reportType,
    );
  }
}

final reportsFilterProvider =
    StateProvider<ReportsFilterState>((ref) => const ReportsFilterState());

typedef SalesFilterState = ReportsFilterState;

/// Alias used by Module 22 sales overview panels.
final salesFilterProvider = reportsFilterProvider;

final reportsSnapshotProvider =
    FutureProvider.autoDispose<ReportsSnapshot>((ref) async {
  final filter = ref.watch(reportsFilterProvider);
  final range = filter.resolve();
  final data = await ref.watch(orderAnalyticsLoaderProvider).load(range);
  const engine = ReportsAnalyticsEngine();

  return engine.compute(
    ReportsAnalyticsInput(
      orders: data.orders,
      items: data.items,
      productCategoryByProductId: data.productCategoryByProductId,
      kitchenCategoryByProductId: data.kitchenCategoryByProductId,
      range: range,
      trendGranularity: filter.trendGranularity,
      topN: filter.topN,
    ),
  );
});

final salesAnalyticsProvider =
    FutureProvider.autoDispose<SalesAnalyticsSnapshot>((ref) async {
  final filter = ref.watch(reportsFilterProvider);
  final range = filter.resolve();
  final data = await ref.watch(orderAnalyticsLoaderProvider).load(range);
  const engine = SalesAnalyticsEngine();

  return engine.compute(
    orders: data.orders,
    items: data.items,
    productCategoryByProductId: data.productCategoryByProductId,
    categoryNameById: data.categoryNameById,
    employeeDisplayName: (userId) {
      final currentUser = ref.read(currentUserProvider);
      if (userId == currentUser.id) return currentUser.name;
      return userId;
    },
  );
});
