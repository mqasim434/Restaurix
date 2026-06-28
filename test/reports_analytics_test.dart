import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/core/utils/date_range_utils.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/order_item.dart';
import 'package:restaurix/domain/services/reports_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportsAnalyticsEngine', () {
    const engine = ReportsAnalyticsEngine();
    final baseTime = DateTime(2024, 6, 21, 12);
    final range = resolveSalesDateRange(
      preset: SalesDateRangePreset.custom,
      customStart: DateTime(2024, 6, 1),
      customEnd: DateTime(2024, 6, 30),
    );

    Order buildOrder({
      required String id,
      OrderStatus status = OrderStatus.received,
      double total = 100,
      double subtotal = 100,
      double itemDiscountTotal = 0,
      double orderDiscountTotal = 0,
      String? cancelReason,
    }) {
      return Order(
        id: id,
        orderNumber: 'ORD-$id',
        orderType: OrderType.dineIn,
        subtotal: subtotal,
        itemDiscountTotal: itemDiscountTotal,
        orderDiscountTotal: orderDiscountTotal,
        total: total,
        paymentType: PaymentType.cash,
        paymentStatus: OrderPaymentStatus.paid,
        status: status,
        isPrepaid: true,
        createdByUserId: 'staff',
        cancelReason: cancelReason,
        createdAt: baseTime,
        updatedAt: baseTime,
        isSynced: false,
        syncAction: SyncAction.create,
        deviceId: 'device',
        version: 1,
      );
    }

    OrderItem buildItem({
      required String orderId,
      String? productId,
      String? dealId,
      String name = 'Burger',
      int quantity = 1,
      double lineTotal = 50,
      DateTime? kitchenReceivedAt,
      DateTime? kitchenReadyAt,
      List<OrderLineDiscount> appliedDiscounts = const [],
    }) {
      return OrderItem(
        id: '$orderId-$name',
        orderId: orderId,
        productId: productId,
        dealId: dealId,
        name: name,
        unitPrice: lineTotal,
        quantity: quantity,
        lineTotal: lineTotal,
        appliedDiscounts: appliedDiscounts,
        kitchenStatus: KitchenStatus.ready,
        kitchenStatusChangedAt: baseTime.add(const Duration(minutes: 12)),
        kitchenReceivedAt: kitchenReceivedAt ?? baseTime,
        kitchenReadyAt: kitchenReadyAt,
        createdAt: baseTime,
        updatedAt: baseTime,
        isSynced: false,
        syncAction: SyncAction.create,
        deviceId: 'device',
        version: 1,
      );
    }

    test('computes peak hours in local time and cancelled order stats', () {
      final noonOrder = buildOrder(
        id: '1',
        total: 80,
        subtotal: 80,
      );
      final cancelled = buildOrder(
        id: '2',
        status: OrderStatus.cancelled,
        total: 40,
        subtotal: 40,
        cancelReason: 'Customer changed mind',
      );

      final snapshot = engine.compute(
        ReportsAnalyticsInput(
          orders: [noonOrder, cancelled],
          items: [
            buildItem(orderId: '1', productId: 'p1', lineTotal: 80),
          ],
          productCategoryByProductId: const {'p1': 'cat-1'},
          kitchenCategoryByProductId: const {'p1': 'Grill'},
          range: range,
          trendGranularity: TrendGranularity.daily,
          topN: 5,
        ),
      );

      expect(snapshot.cancelledOrders.cancelledCount, 1);
      expect(snapshot.cancelledOrders.forfeitedValue, 40);
      expect(snapshot.peakHours[12].orderCount, 1);
      expect(
        snapshot.salesTrend
            .firstWhere((bucket) => bucket.orderCount > 0)
            .netRevenue,
        80,
      );
    });

    test('kitchen performance uses ready timestamps and handles missing data', () {
      final snapshot = engine.compute(
        ReportsAnalyticsInput(
          orders: [buildOrder(id: '1')],
          items: [
            buildItem(
              orderId: '1',
              productId: 'p1',
              kitchenReceivedAt: baseTime,
              kitchenReadyAt: baseTime.add(const Duration(minutes: 10)),
            ),
            buildItem(
              orderId: '1',
              productId: 'p2',
              name: 'Salad',
              kitchenReceivedAt: baseTime,
              kitchenReadyAt: null,
              lineTotal: 20,
            ),
          ],
          productCategoryByProductId: const {'p1': 'cat-1', 'p2': 'cat-2'},
          kitchenCategoryByProductId: const {'p1': 'Grill', 'p2': 'Cold'},
          range: range,
          trendGranularity: TrendGranularity.daily,
          topN: 5,
        ),
      );

      final grill = snapshot.kitchenPerformance
          .firstWhere((row) => row.category == 'Grill');
      expect(grill.averageMinutes, 10);
      expect(
        snapshot.kitchenPerformance.any((row) => row.category == 'Cold'),
        isFalse,
      );
    });

    test('least products excludes zero-sale catalog items', () {
      final snapshot = engine.compute(
        ReportsAnalyticsInput(
          orders: [buildOrder(id: '1')],
          items: [
            buildItem(orderId: '1', productId: 'p1', name: 'Popular', quantity: 5),
            buildItem(
              orderId: '1',
              productId: 'p2',
              name: 'Slow',
              quantity: 1,
              lineTotal: 10,
            ),
          ],
          productCategoryByProductId: const {},
          kitchenCategoryByProductId: const {},
          range: range,
          trendGranularity: TrendGranularity.daily,
          topN: 5,
        ),
      );

      expect(snapshot.leastProducts.first.name, 'Slow');
      expect(snapshot.mostProducts.first.name, 'Popular');
    });
  });
}
