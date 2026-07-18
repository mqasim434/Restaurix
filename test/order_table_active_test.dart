import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';

Order _dineIn({
  OrderStatus status = OrderStatus.received,
  OrderPaymentStatus paymentStatus = OrderPaymentStatus.unpaid,
  String? tableId = 'table-1',
}) {
  final now = DateTime(2024, 6, 21);
  return Order(
    id: 'o1',
    orderNumber: 'ODR-0001',
    orderType: OrderType.dineIn,
    tableId: tableId,
    subtotal: 10,
    itemDiscountTotal: 0,
    orderDiscountTotal: 0,
    total: 10,
    paymentStatus: paymentStatus,
    status: status,
    isPrepaid: false,
    createdByUserId: 'u1',
    createdAt: now,
    updatedAt: now,
    isSynced: true,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

void main() {
  group('Order.isActiveOnTable', () {
    test('open unpaid dine-in holds the table', () {
      expect(_dineIn().isActiveOnTable, isTrue);
    });

    test('paid dine-in no longer holds the table', () {
      expect(
        _dineIn(
          status: OrderStatus.paid,
          paymentStatus: OrderPaymentStatus.paid,
        ).isActiveOnTable,
        isFalse,
      );
    });

    test('completed dine-in no longer holds the table', () {
      expect(
        _dineIn(
          status: OrderStatus.completed,
          paymentStatus: OrderPaymentStatus.paid,
        ).isActiveOnTable,
        isFalse,
      );
    });

    test('completed credit dine-in no longer holds the table', () {
      expect(
        _dineIn(
          status: OrderStatus.completed,
          paymentStatus: OrderPaymentStatus.unpaid,
        ).isActiveOnTable,
        isFalse,
      );
    });
  });
}
