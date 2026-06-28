import '../models/order_enums.dart';
import '../models/sales_analytics.dart';

class DashboardCardMetrics {
  const DashboardCardMetrics({
    required this.todaySales,
    required this.ordersToday,
    required this.preparingCount,
    required this.readyCount,
    required this.servedCount,
    required this.cancelledToday,
    required this.employeesPresent,
    required this.monthlyRevenue,
    required this.averageTicketToday,
  });

  final double todaySales;
  final int ordersToday;
  final int preparingCount;
  final int readyCount;
  final int servedCount;
  final int cancelledToday;
  final int employeesPresent;
  final double monthlyRevenue;
  final double averageTicketToday;

  static const empty = DashboardCardMetrics(
    todaySales: 0,
    ordersToday: 0,
    preparingCount: 0,
    readyCount: 0,
    servedCount: 0,
    cancelledToday: 0,
    employeesPresent: 0,
    monthlyRevenue: 0,
    averageTicketToday: 0,
  );
}

class DashboardTrendPoint {
  const DashboardTrendPoint({
    required this.day,
    required this.label,
    required this.sales,
    required this.orders,
  });

  final DateTime day;
  final String label;
  final double sales;
  final int orders;
}

class DashboardChartsData {
  const DashboardChartsData({
    required this.salesTrend,
    required this.ordersTrend,
    required this.paymentDistribution,
    required this.topProducts,
  });

  final List<DashboardTrendPoint> salesTrend;
  final List<DashboardTrendPoint> ordersTrend;
  final List<PaymentMethodSalesRow> paymentDistribution;
  final List<ProductSalesRow> topProducts;

  static const empty = DashboardChartsData(
    salesTrend: [],
    ordersTrend: [],
    paymentDistribution: [],
    topProducts: [],
  );

  bool get hasTrendData =>
      salesTrend.any((point) => point.sales > 0 || point.orders > 0);

  bool get hasPaymentData =>
      paymentDistribution.any((row) => row.orderCount > 0);

  bool get hasProductData =>
      topProducts.any((row) => row.quantitySold > 0);
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.cards,
    required this.charts,
    required this.generatedAt,
  });

  final DashboardCardMetrics cards;
  final DashboardChartsData charts;
  final DateTime generatedAt;

  static DashboardSnapshot empty({DateTime? now}) {
    return DashboardSnapshot(
      cards: DashboardCardMetrics.empty,
      charts: DashboardChartsData.empty,
      generatedAt: now ?? DateTime.now(),
    );
  }
}

enum DashboardPipelineStatus {
  preparing,
  ready,
  served,
}

DashboardPipelineStatus? pipelineStatusForOrder(OrderStatus status) {
  return switch (status) {
    OrderStatus.preparing => DashboardPipelineStatus.preparing,
    OrderStatus.ready => DashboardPipelineStatus.ready,
    OrderStatus.served => DashboardPipelineStatus.served,
    _ => null,
  };
}
