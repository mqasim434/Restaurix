import 'discount.dart';

enum ReportType {
  salesOverview,
  salesTrend,
  dealsSales,
  discounts,
  cancelledOrders,
  kitchenPerformance,
  peakHours,
  aovTrend,
  mostProducts,
  leastProducts,
}

extension ReportTypeX on ReportType {
  String get label => switch (this) {
        ReportType.salesOverview => 'Sales overview',
        ReportType.salesTrend => 'Sales trend',
        ReportType.dealsSales => 'Deals sales',
        ReportType.discounts => 'Discounts',
        ReportType.cancelledOrders => 'Cancelled orders',
        ReportType.kitchenPerformance => 'Kitchen performance',
        ReportType.peakHours => 'Peak hours',
        ReportType.aovTrend => 'Average order value',
        ReportType.mostProducts => 'Most ordered',
        ReportType.leastProducts => 'Least ordered',
      };
}

class TrendBucket {
  const TrendBucket({
    required this.bucketStart,
    required this.label,
    required this.netRevenue,
    required this.orderCount,
    required this.averageOrderValue,
  });

  final DateTime bucketStart;
  final String label;
  final double netRevenue;
  final int orderCount;
  final double averageOrderValue;
}

class DealSalesRow {
  const DealSalesRow({
    required this.dealKey,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  final String dealKey;
  final String name;
  final int quantitySold;
  final double revenue;
}

class DiscountScopeRow {
  const DiscountScopeRow({
    required this.scope,
    required this.amount,
    required this.count,
  });

  final DiscountScope scope;
  final double amount;
  final int count;
}

class DiscountDetailRow {
  const DiscountDetailRow({
    required this.scope,
    required this.type,
    required this.amount,
    required this.reason,
  });

  final DiscountScope scope;
  final DiscountType type;
  final double amount;
  final String reason;
}

class DiscountReport {
  const DiscountReport({
    required this.totalDiscount,
    required this.byScope,
    required this.details,
  });

  final double totalDiscount;
  final List<DiscountScopeRow> byScope;
  final List<DiscountDetailRow> details;

  static const empty = DiscountReport(
    totalDiscount: 0,
    byScope: [],
    details: [],
  );
}

class CancellationReasonRow {
  const CancellationReasonRow({
    required this.reason,
    required this.count,
  });

  final String reason;
  final int count;
}

class CancelledOrdersReport {
  const CancelledOrdersReport({
    required this.cancelledCount,
    required this.forfeitedValue,
    required this.topReasons,
  });

  final int cancelledCount;
  final double forfeitedValue;
  final List<CancellationReasonRow> topReasons;

  static const empty = CancelledOrdersReport(
    cancelledCount: 0,
    forfeitedValue: 0,
    topReasons: [],
  );
}

class KitchenPerformanceRow {
  const KitchenPerformanceRow({
    required this.category,
    required this.sampleCount,
    required this.averageMinutes,
  });

  final String category;
  final int sampleCount;
  final double? averageMinutes;
}

class PeakHourRow {
  const PeakHourRow({
    required this.hour,
    required this.label,
    required this.orderCount,
  });

  final int hour;
  final String label;
  final int orderCount;
}

class ProductRankingRow {
  const ProductRankingRow({
    required this.key,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  final String key;
  final String name;
  final int quantitySold;
  final double revenue;
}

class ReportsSnapshot {
  const ReportsSnapshot({
    required this.salesTrend,
    required this.dealsSales,
    required this.discountReport,
    required this.cancelledOrders,
    required this.kitchenPerformance,
    required this.peakHours,
    required this.aovTrend,
    required this.mostProducts,
    required this.leastProducts,
  });

  final List<TrendBucket> salesTrend;
  final List<DealSalesRow> dealsSales;
  final DiscountReport discountReport;
  final CancelledOrdersReport cancelledOrders;
  final List<KitchenPerformanceRow> kitchenPerformance;
  final List<PeakHourRow> peakHours;
  final List<TrendBucket> aovTrend;
  final List<ProductRankingRow> mostProducts;
  final List<ProductRankingRow> leastProducts;

  bool get isEmpty =>
      salesTrend.every((bucket) => bucket.orderCount == 0) &&
      cancelledOrders.cancelledCount == 0;
}
