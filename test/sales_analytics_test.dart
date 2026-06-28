import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/order_item.dart';
import 'package:restaurix/domain/services/sales_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesAnalyticsEngine', () {
    const engine = SalesAnalyticsEngine();

    final baseTime = DateTime(2024, 6, 21, 12);

    Order buildOrder({
      required String id,
      OrderStatus status = OrderStatus.received,
      OrderType orderType = OrderType.dineIn,
      PaymentType? paymentType = PaymentType.cash,
      double subtotal = 100,
      double itemDiscountTotal = 10,
      double orderDiscountTotal = 5,
      double total = 85,
      String createdByUserId = 'staff-1',
    }) {
      return Order(
        id: id,
        orderNumber: 'ORD-$id',
        orderType: orderType,
        subtotal: subtotal,
        itemDiscountTotal: itemDiscountTotal,
        orderDiscountTotal: orderDiscountTotal,
        total: total,
        paymentType: paymentType,
        paymentStatus: OrderPaymentStatus.paid,
        status: status,
        isPrepaid: true,
        createdByUserId: createdByUserId,
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
    }) {
      return OrderItem(
        id: '$orderId-item',
        orderId: orderId,
        productId: productId,
        dealId: dealId,
        name: name,
        unitPrice: lineTotal,
        quantity: quantity,
        lineTotal: lineTotal,
        kitchenStatus: KitchenStatus.received,
        kitchenStatusChangedAt: baseTime,
        createdAt: baseTime,
        updatedAt: baseTime,
        isSynced: false,
        syncAction: SyncAction.create,
        deviceId: 'device',
        version: 1,
      );
    }

    test('excludes cancelled orders from revenue but counts them separately', () {
      final snapshot = engine.compute(
        orders: [
          buildOrder(id: '1', total: 100, subtotal: 100),
          buildOrder(
            id: '2',
            status: OrderStatus.cancelled,
            total: 200,
            subtotal: 200,
          ),
        ],
        items: [
          buildItem(orderId: '1', productId: 'p1', lineTotal: 100),
          buildItem(orderId: '2', productId: 'p1', lineTotal: 200),
        ],
        productCategoryByProductId: const {'p1': 'cat-1'},
        categoryNameById: const {'cat-1': 'Mains'},
      );

      expect(snapshot.overall.orderCount, 1);
      expect(snapshot.overall.cancelledOrderCount, 1);
      expect(snapshot.overall.netRevenue, 100);
      expect(snapshot.overall.grossRevenue, 100);
      expect(snapshot.products.single.revenue, 100);
    });

    test('computes net, gross, and discount totals', () {
      final snapshot = engine.compute(
        orders: [
          buildOrder(
            id: '1',
            subtotal: 100,
            itemDiscountTotal: 10,
            orderDiscountTotal: 5,
            total: 85,
          ),
        ],
        items: [
          buildItem(orderId: '1', productId: 'p1', lineTotal: 85),
        ],
        productCategoryByProductId: const {'p1': 'cat-1'},
        categoryNameById: const {'cat-1': 'Mains'},
      );

      expect(snapshot.overall.netRevenue, 85);
      expect(snapshot.overall.grossRevenue, 100);
      expect(snapshot.overall.totalDiscounts, 15);
      expect(snapshot.overall.averageOrderValue, 85);
    });

    test('groups product, category, payment, and employee slices', () {
      final snapshot = engine.compute(
        orders: [
          buildOrder(
            id: '1',
            orderType: OrderType.takeaway,
            paymentType: PaymentType.card,
            total: 30,
            subtotal: 30,
            createdByUserId: 'staff-1',
          ),
          buildOrder(
            id: '2',
            orderType: OrderType.delivery,
            paymentType: PaymentType.online,
            total: 20,
            subtotal: 20,
            createdByUserId: 'staff-2',
          ),
        ],
        items: [
          buildItem(orderId: '1', productId: 'p1', name: 'Burger', lineTotal: 20),
          buildItem(orderId: '1', dealId: 'd1', name: 'Combo', lineTotal: 10),
          buildItem(orderId: '2', productId: 'p2', name: 'Fries', lineTotal: 20),
        ],
        productCategoryByProductId: const {
          'p1': 'cat-1',
          'p2': 'cat-2',
        },
        categoryNameById: const {
          'cat-1': 'Mains',
          'cat-2': 'Sides',
        },
        employeeDisplayName: (userId) => userId == 'staff-1' ? 'Alice' : 'Bob',
      );

      expect(snapshot.overall.orderCount, 2);
      expect(snapshot.overall.byOrderType.length, 2);
      expect(snapshot.products.length, 3);
      expect(snapshot.categories.map((row) => row.categoryName), [
        'Mains',
        'Sides',
        'Deals',
      ]);
      expect(snapshot.paymentMethods.length, 2);
      expect(snapshot.employees.first.displayName, 'Alice');
      expect(snapshot.employees.first.netRevenue, 30);
    });
  });
}
