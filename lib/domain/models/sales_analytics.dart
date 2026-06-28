import '../models/order_enums.dart';

class OrderTypeSalesBreakdown {
  const OrderTypeSalesBreakdown({
    required this.orderType,
    required this.orderCount,
    required this.netRevenue,
    required this.grossRevenue,
  });

  final OrderType orderType;
  final int orderCount;
  final double netRevenue;
  final double grossRevenue;
}

class OverallSalesSummary {
  const OverallSalesSummary({
    required this.orderCount,
    required this.cancelledOrderCount,
    required this.netRevenue,
    required this.grossRevenue,
    required this.totalDiscounts,
    required this.averageOrderValue,
    required this.byOrderType,
  });

  final int orderCount;
  final int cancelledOrderCount;
  final double netRevenue;
  final double grossRevenue;
  final double totalDiscounts;
  final double averageOrderValue;
  final List<OrderTypeSalesBreakdown> byOrderType;

  static const empty = OverallSalesSummary(
    orderCount: 0,
    cancelledOrderCount: 0,
    netRevenue: 0,
    grossRevenue: 0,
    totalDiscounts: 0,
    averageOrderValue: 0,
    byOrderType: [],
  );
}

class ProductSalesRow {
  const ProductSalesRow({
    required this.key,
    required this.name,
    required this.isDeal,
    required this.quantitySold,
    required this.revenue,
  });

  final String key;
  final String name;
  final bool isDeal;
  final int quantitySold;
  final double revenue;
}

class CategorySalesRow {
  const CategorySalesRow({
    required this.categoryKey,
    required this.categoryName,
    required this.quantitySold,
    required this.revenue,
  });

  final String categoryKey;
  final String categoryName;
  final int quantitySold;
  final double revenue;
}

class PaymentMethodSalesRow {
  const PaymentMethodSalesRow({
    required this.paymentType,
    required this.label,
    required this.orderCount,
    required this.netRevenue,
  });

  final PaymentType? paymentType;
  final String label;
  final int orderCount;
  final double netRevenue;
}

class EmployeeSalesRow {
  const EmployeeSalesRow({
    required this.userId,
    required this.displayName,
    required this.orderCount,
    required this.netRevenue,
  });

  final String userId;
  final String displayName;
  final int orderCount;
  final double netRevenue;
}

class SalesAnalyticsSnapshot {
  const SalesAnalyticsSnapshot({
    required this.overall,
    required this.products,
    required this.categories,
    required this.paymentMethods,
    required this.employees,
  });

  final OverallSalesSummary overall;
  final List<ProductSalesRow> products;
  final List<CategorySalesRow> categories;
  final List<PaymentMethodSalesRow> paymentMethods;
  final List<EmployeeSalesRow> employees;

  bool get isEmpty =>
      overall.orderCount == 0 && overall.cancelledOrderCount == 0;
}
