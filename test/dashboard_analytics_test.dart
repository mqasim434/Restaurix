import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/services/dashboard_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

Order _order({
  required String id,
  required DateTime createdAt,
  OrderStatus status = OrderStatus.paid,
  double total = 100,
  PaymentType? paymentType = PaymentType.cash,
}) {
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    orderType: OrderType.takeaway,
    status: status,
    paymentStatus: OrderPaymentStatus.paid,
    paymentType: paymentType,
    subtotal: total,
    itemDiscountTotal: 0,
    orderDiscountTotal: 0,
    total: total,
    isPrepaid: true,
    isHeld: false,
    createdByUserId: 'admin',
    createdAt: createdAt,
    updatedAt: createdAt,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'device',
    version: 1,
  );
}

void main() {
  group('DashboardAnalyticsEngine', () {
    test('returns zero-state metrics on empty data', () {
      final snapshot = DashboardAnalyticsEngine.compute(
        DashboardAnalyticsInput(
          orders: const [],
          items: const [],
          productCategoryByProductId: const {},
          categoryNameById: const {},
          employeesPresent: 0,
          now: DateTime(2024, 6, 15, 12),
        ),
      );

      expect(snapshot.cards.todaySales, 0);
      expect(snapshot.cards.ordersToday, 0);
      expect(snapshot.cards.employeesPresent, 0);
      expect(snapshot.cards.monthlyRevenue, 0);
      expect(snapshot.charts.hasTrendData, isFalse);
      expect(snapshot.charts.hasPaymentData, isFalse);
      expect(snapshot.charts.hasProductData, isFalse);
    });

    test('computes today and pipeline metrics from orders', () {
      final now = DateTime(2024, 6, 15, 12);
      final orders = [
        _order(id: '1', createdAt: now, total: 50),
        _order(
          id: '2',
          createdAt: now,
          status: OrderStatus.preparing,
          total: 30,
        ),
        _order(
          id: '3',
          createdAt: now,
          status: OrderStatus.ready,
          total: 20,
        ),
        _order(
          id: '4',
          createdAt: now,
          status: OrderStatus.cancelled,
          total: 0,
        ),
      ];

      final snapshot = DashboardAnalyticsEngine.compute(
        DashboardAnalyticsInput(
          orders: orders,
          items: const [],
          productCategoryByProductId: const {},
          categoryNameById: const {},
          employeesPresent: 2,
          now: now,
        ),
      );

      expect(snapshot.cards.todaySales, 100);
      expect(snapshot.cards.ordersToday, 4);
      expect(snapshot.cards.preparingCount, 1);
      expect(snapshot.cards.readyCount, 1);
      expect(snapshot.cards.cancelledToday, 1);
      expect(snapshot.cards.employeesPresent, 2);
      expect(snapshot.cards.averageTicketToday, closeTo(100 / 3, 0.01));
    });

    test('builds 30-day trend buckets even when only recent orders exist', () {
      final now = DateTime(2024, 6, 15, 12);
      final snapshot = DashboardAnalyticsEngine.compute(
        DashboardAnalyticsInput(
          orders: [
            _order(id: '1', createdAt: now, total: 80),
            _order(
              id: '2',
              createdAt: now.subtract(const Duration(days: 3)),
              total: 40,
            ),
          ],
          items: const [],
          productCategoryByProductId: const {},
          categoryNameById: const {},
          employeesPresent: 0,
          now: now,
        ),
      );

      expect(snapshot.charts.salesTrend, hasLength(30));
      expect(
        snapshot.charts.salesTrend.last.sales,
        80,
      );
      expect(snapshot.charts.hasTrendData, isTrue);
    });
  });
}
