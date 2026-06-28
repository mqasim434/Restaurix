import '../../core/utils/date_range_utils.dart';
import '../models/dashboard.dart';
import '../models/order.dart';
import '../models/order_enums.dart';
import '../models/order_item.dart';
import 'reports_analytics.dart';
import 'sales_analytics.dart';

class DashboardAnalyticsInput {
  const DashboardAnalyticsInput({
    required this.orders,
    required this.items,
    required this.productCategoryByProductId,
    required this.categoryNameById,
    required this.employeesPresent,
    this.now,
    this.topProductCount = 5,
  });

  final List<Order> orders;
  final List<OrderItem> items;
  final Map<String, String> productCategoryByProductId;
  final Map<String, String> categoryNameById;
  final int employeesPresent;
  final DateTime? now;
  final int topProductCount;
}

abstract final class DashboardAnalyticsEngine {
  static const _salesEngine = SalesAnalyticsEngine();
  static const _reportsEngine = ReportsAnalyticsEngine();

  static DashboardSnapshot compute(DashboardAnalyticsInput input) {
    final anchor = input.now ?? DateTime.now();
    final todayRange = resolveSalesDateRange(
      preset: SalesDateRangePreset.today,
      now: anchor,
    );
    final monthRange = resolveSalesDateRange(
      preset: SalesDateRangePreset.thisMonth,
      now: anchor,
    );
    final last30Start = startOfLocalDay(anchor).subtract(const Duration(days: 29));
    final last30Range = SalesDateRange(
      preset: SalesDateRangePreset.custom,
      startInclusive: last30Start,
      endExclusive: endOfLocalDayExclusive(anchor),
      customStart: last30Start,
      customEnd: startOfLocalDay(anchor),
    );

    final todayOrders = _ordersInRange(input.orders, todayRange);
    final monthOrders = _ordersInRange(input.orders, monthRange);
    final last30Orders = _ordersInRange(input.orders, last30Range);
    final last30OrderIds = last30Orders.map((order) => order.id).toSet();
    final last30Items = input.items
        .where((item) => last30OrderIds.contains(item.orderId))
        .toList();

    final todaySummary = _salesEngine.compute(
      orders: todayOrders,
      items: input.items,
      productCategoryByProductId: input.productCategoryByProductId,
      categoryNameById: input.categoryNameById,
    );

    final monthSummary = _salesEngine.compute(
      orders: monthOrders,
      items: input.items,
      productCategoryByProductId: input.productCategoryByProductId,
      categoryNameById: input.categoryNameById,
    );

    final chartsAnalytics = _salesEngine.compute(
      orders: last30Orders,
      items: last30Items,
      productCategoryByProductId: input.productCategoryByProductId,
      categoryNameById: input.categoryNameById,
    );

    final trend = _reportsEngine.compute(
      ReportsAnalyticsInput(
        orders: last30Orders,
        items: last30Items,
        productCategoryByProductId: input.productCategoryByProductId,
        kitchenCategoryByProductId: const {},
        range: last30Range,
        trendGranularity: TrendGranularity.daily,
        topN: input.topProductCount,
      ),
    );

    final cards = DashboardCardMetrics(
      todaySales: todaySummary.overall.netRevenue,
      ordersToday: todayOrders.length,
      preparingCount: _countPipeline(input.orders, OrderStatus.preparing),
      readyCount: _countPipeline(input.orders, OrderStatus.ready),
      servedCount: _countPipeline(input.orders, OrderStatus.served),
      cancelledToday: todayOrders
          .where((order) => order.status == OrderStatus.cancelled)
          .length,
      employeesPresent: input.employeesPresent,
      monthlyRevenue: monthSummary.overall.netRevenue,
      averageTicketToday: todaySummary.overall.averageOrderValue,
    );

    final trendPoints = [
      for (final bucket in trend.salesTrend)
        DashboardTrendPoint(
          day: bucket.bucketStart,
          label: bucket.label,
          sales: bucket.netRevenue,
          orders: bucket.orderCount,
        ),
    ];

    final charts = DashboardChartsData(
      salesTrend: trendPoints,
      ordersTrend: trendPoints,
      paymentDistribution: chartsAnalytics.paymentMethods,
      topProducts: chartsAnalytics.products
          .take(input.topProductCount)
          .toList(growable: false),
    );

    return DashboardSnapshot(
      cards: cards,
      charts: charts,
      generatedAt: anchor,
    );
  }

  static List<Order> _ordersInRange(
    List<Order> orders,
    SalesDateRange range,
  ) {
    return orders.where((order) => range.contains(order.createdAt)).toList();
  }

  static int _countPipeline(List<Order> orders, OrderStatus status) {
    return orders.where((order) => order.status == status).length;
  }
}
