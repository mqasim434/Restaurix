import '../models/order.dart';
import '../models/order_enums.dart';
import '../models/order_item.dart';
import '../models/sales_analytics.dart';

const _dealsCategoryKey = 'deals';
const _dealsCategoryName = 'Deals';
const _uncategorizedKey = 'uncategorized';
const _uncategorizedName = 'Uncategorized';

class SalesAnalyticsEngine {
  const SalesAnalyticsEngine();

  SalesAnalyticsSnapshot compute({
    required List<Order> orders,
    required List<OrderItem> items,
    required Map<String, String> productCategoryByProductId,
    required Map<String, String> categoryNameById,
    String Function(String userId)? employeeDisplayName,
  }) {
    final revenueOrders =
        orders.where((order) => order.status != OrderStatus.cancelled).toList();
    final cancelledCount =
        orders.where((order) => order.status == OrderStatus.cancelled).length;

    final revenueOrderIds = revenueOrders.map((order) => order.id).toSet();
    final revenueItems = items
        .where((item) => revenueOrderIds.contains(item.orderId))
        .toList();

    final overall = _computeOverall(
      revenueOrders: revenueOrders,
      cancelledCount: cancelledCount,
    );

    return SalesAnalyticsSnapshot(
      overall: overall,
      products: _computeProductRows(revenueItems),
      categories: _computeCategoryRows(
        items: revenueItems,
        productCategoryByProductId: productCategoryByProductId,
        categoryNameById: categoryNameById,
      ),
      paymentMethods: _computePaymentRows(revenueOrders),
      employees: _computeEmployeeRows(
        revenueOrders: revenueOrders,
        employeeDisplayName: employeeDisplayName ?? _defaultEmployeeName,
      ),
    );
  }

  OverallSalesSummary _computeOverall({
    required List<Order> revenueOrders,
    required int cancelledCount,
  }) {
    if (revenueOrders.isEmpty) {
      return OverallSalesSummary.empty.copyWithCancelled(cancelledCount);
    }

    var netRevenue = 0.0;
    var grossRevenue = 0.0;
    var totalDiscounts = 0.0;

    final byType = <OrderType, _MutableTypeTotals>{};

    for (final order in revenueOrders) {
      netRevenue += order.total;
      grossRevenue += order.subtotal;
      totalDiscounts += order.itemDiscountTotal + order.orderDiscountTotal;

      final bucket = byType.putIfAbsent(order.orderType, _MutableTypeTotals.new);
      bucket.orderCount += 1;
      bucket.netRevenue += order.total;
      bucket.grossRevenue += order.subtotal;
    }

    final orderCount = revenueOrders.length;

    return OverallSalesSummary(
      orderCount: orderCount,
      cancelledOrderCount: cancelledCount,
      netRevenue: netRevenue,
      grossRevenue: grossRevenue,
      totalDiscounts: totalDiscounts,
      averageOrderValue: orderCount == 0 ? 0 : netRevenue / orderCount,
      byOrderType: OrderType.values
          .map((type) {
            final totals = byType[type];
            if (totals == null || totals.orderCount == 0) return null;
            return OrderTypeSalesBreakdown(
              orderType: type,
              orderCount: totals.orderCount,
              netRevenue: totals.netRevenue,
              grossRevenue: totals.grossRevenue,
            );
          })
          .whereType<OrderTypeSalesBreakdown>()
          .toList(),
    );
  }

  List<ProductSalesRow> _computeProductRows(List<OrderItem> items) {
    final rows = <String, _MutableProductTotals>{};

    for (final item in items) {
      final key = item.dealId ?? item.productId ?? item.name;
      final row = rows.putIfAbsent(key, () {
        return _MutableProductTotals(
          key: key,
          name: item.name,
          isDeal: item.dealId != null,
        );
      });
      row.quantitySold += item.quantity;
      row.revenue += item.lineTotal;
    }

    final result = rows.values
        .map(
          (row) => ProductSalesRow(
            key: row.key,
            name: row.name,
            isDeal: row.isDeal,
            quantitySold: row.quantitySold,
            revenue: row.revenue,
          ),
        )
        .toList();

    result.sort((a, b) => b.revenue.compareTo(a.revenue));
    return result;
  }

  List<CategorySalesRow> _computeCategoryRows({
    required List<OrderItem> items,
    required Map<String, String> productCategoryByProductId,
    required Map<String, String> categoryNameById,
  }) {
    final rows = <String, _MutableCategoryTotals>{};

    for (final item in items) {
      final categoryKey = _resolveCategoryKey(
        item: item,
        productCategoryByProductId: productCategoryByProductId,
      );
      final categoryName = _resolveCategoryName(
        categoryKey: categoryKey,
        categoryNameById: categoryNameById,
      );

      final row = rows.putIfAbsent(
        categoryKey,
        () => _MutableCategoryTotals(
          categoryKey: categoryKey,
          categoryName: categoryName,
        ),
      );
      row.quantitySold += item.quantity;
      row.revenue += item.lineTotal;
    }

    final result = rows.values
        .map(
          (row) => CategorySalesRow(
            categoryKey: row.categoryKey,
            categoryName: row.categoryName,
            quantitySold: row.quantitySold,
            revenue: row.revenue,
          ),
        )
        .toList();

    result.sort((a, b) => b.revenue.compareTo(a.revenue));
    return result;
  }

  List<PaymentMethodSalesRow> _computePaymentRows(List<Order> revenueOrders) {
    final rows = <PaymentType?, _MutablePaymentTotals>{};

    for (final order in revenueOrders) {
      final bucket =
          rows.putIfAbsent(order.paymentType, _MutablePaymentTotals.new);
      bucket.orderCount += 1;
      bucket.netRevenue += order.total;
    }

    final result = rows.entries
        .map(
          (entry) => PaymentMethodSalesRow(
            paymentType: entry.key,
            label: entry.key?.label ?? 'Not specified',
            orderCount: entry.value.orderCount,
            netRevenue: entry.value.netRevenue,
          ),
        )
        .toList();

    result.sort((a, b) => b.netRevenue.compareTo(a.netRevenue));
    return result;
  }

  List<EmployeeSalesRow> _computeEmployeeRows({
    required List<Order> revenueOrders,
    required String Function(String userId) employeeDisplayName,
  }) {
    final rows = <String, _MutableEmployeeTotals>{};

    for (final order in revenueOrders) {
      final bucket = rows.putIfAbsent(
        order.createdByUserId,
        () => _MutableEmployeeTotals(
          userId: order.createdByUserId,
          displayName: employeeDisplayName(order.createdByUserId),
        ),
      );
      bucket.orderCount += 1;
      bucket.netRevenue += order.total;
    }

    final result = rows.values
        .map(
          (row) => EmployeeSalesRow(
            userId: row.userId,
            displayName: row.displayName,
            orderCount: row.orderCount,
            netRevenue: row.netRevenue,
          ),
        )
        .toList();

    result.sort((a, b) => b.netRevenue.compareTo(a.netRevenue));
    return result;
  }

  String _resolveCategoryKey({
    required OrderItem item,
    required Map<String, String> productCategoryByProductId,
  }) {
    if (item.dealId != null) return _dealsCategoryKey;
    final productId = item.productId;
    if (productId == null) return _uncategorizedKey;
    return productCategoryByProductId[productId] ?? _uncategorizedKey;
  }

  String _resolveCategoryName({
    required String categoryKey,
    required Map<String, String> categoryNameById,
  }) {
    if (categoryKey == _dealsCategoryKey) return _dealsCategoryName;
    if (categoryKey == _uncategorizedKey) return _uncategorizedName;
    return categoryNameById[categoryKey] ?? _uncategorizedName;
  }

  static String _defaultEmployeeName(String userId) => userId;
}

class _MutableTypeTotals {
  int orderCount = 0;
  double netRevenue = 0;
  double grossRevenue = 0;
}

class _MutableProductTotals {
  _MutableProductTotals({
    required this.key,
    required this.name,
    required this.isDeal,
  });

  final String key;
  final String name;
  final bool isDeal;
  int quantitySold = 0;
  double revenue = 0;
}

class _MutableCategoryTotals {
  _MutableCategoryTotals({
    required this.categoryKey,
    required this.categoryName,
  });

  final String categoryKey;
  final String categoryName;
  int quantitySold = 0;
  double revenue = 0;
}

class _MutablePaymentTotals {
  int orderCount = 0;
  double netRevenue = 0;
}

class _MutableEmployeeTotals {
  _MutableEmployeeTotals({
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;
  int orderCount = 0;
  double netRevenue = 0;
}

extension on OverallSalesSummary {
  OverallSalesSummary copyWithCancelled(int cancelledOrderCount) {
    return OverallSalesSummary(
      orderCount: orderCount,
      cancelledOrderCount: cancelledOrderCount,
      netRevenue: netRevenue,
      grossRevenue: grossRevenue,
      totalDiscounts: totalDiscounts,
      averageOrderValue: averageOrderValue,
      byOrderType: byOrderType,
    );
  }
}
