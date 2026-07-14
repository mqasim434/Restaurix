import '../../core/utils/date_range_utils.dart';
import '../models/discount.dart';
import '../models/order.dart';
import '../models/order_enums.dart';
import '../models/order_item.dart';
import '../models/reports.dart';

const _uncategorizedKitchen = 'Uncategorized';

class ReportsAnalyticsInput {
  const ReportsAnalyticsInput({
    required this.orders,
    required this.items,
    required this.productCategoryByProductId,
    required this.kitchenCategoryByProductId,
    required this.range,
    required this.trendGranularity,
    required this.topN,
  });

  final List<Order> orders;
  final List<OrderItem> items;
  final Map<String, String> productCategoryByProductId;
  final Map<String, String> kitchenCategoryByProductId;
  final SalesDateRange range;
  final TrendGranularity trendGranularity;
  final int topN;
}

class ReportsAnalyticsEngine {
  const ReportsAnalyticsEngine();

  ReportsSnapshot compute(ReportsAnalyticsInput input) {
    final revenueOrders = input.orders
        .where((order) => order.status != OrderStatus.cancelled)
        .toList();
    final revenueOrderIds = revenueOrders.map((order) => order.id).toSet();
    final revenueItems = input.items
        .where((item) => revenueOrderIds.contains(item.orderId))
        .toList();

    return ReportsSnapshot(
      salesTrend: _computeTrend(
        orders: revenueOrders,
        range: input.range,
        granularity: input.trendGranularity,
      ),
      dealsSales: _computeDealsSales(revenueItems),
      discountReport: _computeDiscountReport(
        revenueOrders: revenueOrders,
        revenueItems: revenueItems,
      ),
      cancelledOrders: _computeCancelledOrders(input.orders),
      kitchenPerformance: _computeKitchenPerformance(
        items: revenueItems,
        kitchenCategoryByProductId: input.kitchenCategoryByProductId,
      ),
      peakHours: _computePeakHours(revenueOrders),
      aovTrend: _computeAovTrend(
        orders: revenueOrders,
        range: input.range,
        granularity: input.trendGranularity,
      ),
      mostProducts: _computeProductRanking(
        items: revenueItems,
        topN: input.topN,
        ascending: false,
      ),
      leastProducts: _computeProductRanking(
        items: revenueItems,
        topN: input.topN,
        ascending: true,
      ),
    );
  }

  List<TrendBucket> _computeTrend({
    required List<Order> orders,
    required SalesDateRange range,
    required TrendGranularity granularity,
  }) {
    final totalsByBucket = <DateTime, _TrendTotals>{};

    for (final order in orders) {
      final bucket = trendBucketStart(order.createdAt, granularity);
      final totals = totalsByBucket.putIfAbsent(bucket, _TrendTotals.new);
      totals.orderCount += 1;
      totals.netRevenue += order.total;
    }

    return [
      for (final bucketStart in iterateTrendBuckets(
        range: range,
        granularity: granularity,
      ))
        _toTrendBucket(
          bucketStart: bucketStart,
          granularity: granularity,
          totals: totalsByBucket[bucketStart] ?? _TrendTotals(),
        ),
    ];
  }

  List<TrendBucket> _computeAovTrend({
    required List<Order> orders,
    required SalesDateRange range,
    required TrendGranularity granularity,
  }) {
    return _computeTrend(
      orders: orders,
      range: range,
      granularity: granularity,
    );
  }

  TrendBucket _toTrendBucket({
    required DateTime bucketStart,
    required TrendGranularity granularity,
    required _TrendTotals totals,
  }) {
    return TrendBucket(
      bucketStart: bucketStart,
      label: trendBucketLabel(bucketStart, granularity),
      netRevenue: totals.netRevenue,
      orderCount: totals.orderCount,
      averageOrderValue: totals.orderCount == 0
          ? 0
          : totals.netRevenue / totals.orderCount,
    );
  }

  List<DealSalesRow> _computeDealsSales(List<OrderItem> items) {
    final rows = <String, _MutableDealTotals>{};

    for (final item in items) {
      if (item.dealId == null) continue;
      final row = rows.putIfAbsent(
        item.dealId!,
        () => _MutableDealTotals(
          dealKey: item.dealId!,
          name: item.name,
        ),
      );
      row.quantitySold += item.quantity;
      row.revenue += item.lineTotal;
    }

    final result = rows.values
        .map(
          (row) => DealSalesRow(
            dealKey: row.dealKey,
            name: row.name,
            quantitySold: row.quantitySold,
            revenue: row.revenue,
          ),
        )
        .toList();
    result.sort((a, b) => b.revenue.compareTo(a.revenue));
    return result;
  }

  DiscountReport _computeDiscountReport({
    required List<Order> revenueOrders,
    required List<OrderItem> revenueItems,
  }) {
    final scopeTotals = <DiscountScope, _MutableDiscountScopeTotals>{};
    final details = <String, _MutableDiscountDetail>{};
    var totalDiscount = 0.0;

    for (final item in revenueItems) {
      for (final discount in item.appliedDiscounts) {
        totalDiscount += discount.amountApplied;
        _accumulateScope(scopeTotals, discount);
        _accumulateDetail(details, discount);
      }
    }

    for (final order in revenueOrders) {
      if (order.orderDiscountTotal <= 0 || order.orderDiscountType == null) {
        continue;
      }

      totalDiscount += order.orderDiscountTotal;
      final discount = OrderLineDiscount(
        scope: DiscountScope.wholeOrder,
        type: DiscountType.values.byName(order.orderDiscountType!),
        value: order.orderDiscountValue ?? 0,
        amountApplied: order.orderDiscountTotal,
        reason: order.orderDiscountReason,
      );
      _accumulateScope(scopeTotals, discount);
      _accumulateDetail(details, discount);
    }

    return DiscountReport(
      totalDiscount: totalDiscount,
      byScope: DiscountScope.values
          .map((scope) {
            final totals = scopeTotals[scope];
            if (totals == null || totals.amount == 0) return null;
            return DiscountScopeRow(
              scope: scope,
              amount: totals.amount,
              count: totals.count,
            );
          })
          .whereType<DiscountScopeRow>()
          .toList(),
      details: details.values
          .map(
            (row) => DiscountDetailRow(
              scope: row.scope,
              type: row.type,
              amount: row.amount,
              reason: row.reason,
            ),
          )
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount)),
    );
  }

  void _accumulateScope(
    Map<DiscountScope, _MutableDiscountScopeTotals> scopeTotals,
    OrderLineDiscount discount,
  ) {
    final bucket =
        scopeTotals.putIfAbsent(discount.scope, _MutableDiscountScopeTotals.new);
    bucket.amount += discount.amountApplied;
    bucket.count += 1;
  }

  void _accumulateDetail(
    Map<String, _MutableDiscountDetail> details,
    OrderLineDiscount discount,
  ) {
    final reason = (discount.reason?.trim().isEmpty ?? true)
        ? 'No reason provided'
        : discount.reason!.trim();
    final key = '${discount.scope.name}|${discount.type.name}|$reason';
    final row = details.putIfAbsent(
      key,
      () => _MutableDiscountDetail(
        scope: discount.scope,
        type: discount.type,
        reason: reason,
      ),
    );
    row.amount += discount.amountApplied;
  }

  CancelledOrdersReport _computeCancelledOrders(List<Order> orders) {
    final cancelled =
        orders.where((order) => order.status == OrderStatus.cancelled).toList();
    if (cancelled.isEmpty) return CancelledOrdersReport.empty;

    final reasonCounts = <String, int>{};
    var forfeitedValue = 0.0;

    for (final order in cancelled) {
      forfeitedValue += order.total;
      final reason = order.cancelReason?.trim().isEmpty ?? true
          ? 'No reason provided'
          : order.cancelReason!.trim();
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }

    final topReasons = reasonCounts.entries
        .map(
          (entry) => CancellationReasonRow(
            reason: entry.key,
            count: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return CancelledOrdersReport(
      cancelledCount: cancelled.length,
      forfeitedValue: forfeitedValue,
      topReasons: topReasons,
    );
  }

  List<KitchenPerformanceRow> _computeKitchenPerformance({
    required List<OrderItem> items,
    required Map<String, String> kitchenCategoryByProductId,
  }) {
    final samples = <String, List<double>>{};

    for (final item in items) {
      final received = item.kitchenReceivedAt ?? item.createdAt;
      final ready = item.kitchenReadyAt;
      if (ready == null) continue;

      final minutes = ready.difference(received).inMinutes.toDouble();
      if (minutes.isNegative) continue;

      final category = _resolveKitchenCategory(
        item: item,
        kitchenCategoryByProductId: kitchenCategoryByProductId,
      );
      samples.putIfAbsent(category, () => []).add(minutes);
    }

    final result = samples.entries
        .map(
          (entry) => KitchenPerformanceRow(
            category: entry.key,
            sampleCount: entry.value.length,
            averageMinutes: entry.value.isEmpty
                ? null
                : entry.value.reduce((a, b) => a + b) / entry.value.length,
          ),
        )
        .toList()
      ..sort((a, b) {
        final aMinutes = a.averageMinutes ?? double.infinity;
        final bMinutes = b.averageMinutes ?? double.infinity;
        return aMinutes.compareTo(bMinutes);
      });

    if (result.isEmpty) {
      return const [
        KitchenPerformanceRow(
          category: _uncategorizedKitchen,
          sampleCount: 0,
          averageMinutes: null,
        ),
      ];
    }

    return result;
  }

  String _resolveKitchenCategory({
    required OrderItem item,
    required Map<String, String> kitchenCategoryByProductId,
  }) {
    if (item.dealId != null) return 'Deals';
    final productId = item.productId;
    if (productId == null) return _uncategorizedKitchen;
    final category = kitchenCategoryByProductId[productId]?.trim();
    if (category == null || category.isEmpty) return _uncategorizedKitchen;
    return category;
  }

  List<PeakHourRow> _computePeakHours(List<Order> orders) {
    final counts = List<int>.filled(24, 0);

    for (final order in orders) {
      final hour = order.createdAt.toLocal().hour;
      counts[hour] += 1;
    }

    return [
      for (var hour = 0; hour < 24; hour++)
        PeakHourRow(
          hour: hour,
          label: _hourLabel(hour),
          orderCount: counts[hour],
        ),
    ];
  }

  String _hourLabel(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour $period';
  }

  List<ProductRankingRow> _computeProductRanking({
    required List<OrderItem> items,
    required int topN,
    required bool ascending,
  }) {
    final rows = <String, _MutableProductTotals>{};

    for (final item in items) {
      if (item.dealId != null) continue;
      final key = item.productId ?? item.name;
      final row = rows.putIfAbsent(
        key,
        () => _MutableProductTotals(key: key, name: item.name),
      );
      row.quantitySold += item.quantity;
      row.revenue += item.lineTotal;
    }

    final result = rows.values
        .map(
          (row) => ProductRankingRow(
            key: row.key,
            name: row.name,
            quantitySold: row.quantitySold,
            revenue: row.revenue,
          ),
        )
        .toList();

    result.sort((a, b) {
      final comparison = a.quantitySold.compareTo(b.quantitySold);
      return ascending ? comparison : -comparison;
    });

    if (result.length <= topN) return result;
    return result.sublist(0, topN);
  }
}

class _TrendTotals {
  int orderCount = 0;
  double netRevenue = 0;
}

class _MutableDealTotals {
  _MutableDealTotals({required this.dealKey, required this.name});

  final String dealKey;
  final String name;
  int quantitySold = 0;
  double revenue = 0;
}

class _MutableDiscountScopeTotals {
  double amount = 0;
  int count = 0;
}

class _MutableDiscountDetail {
  _MutableDiscountDetail({
    required this.scope,
    required this.type,
    required this.reason,
  });

  final DiscountScope scope;
  final DiscountType type;
  final String reason;
  double amount = 0;
}

class _MutableProductTotals {
  _MutableProductTotals({required this.key, required this.name});

  final String key;
  final String name;
  int quantitySold = 0;
  double revenue = 0;
}
