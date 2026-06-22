import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/user_role.dart';
import 'package:restaurix/domain/services/order_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

Order _order({
  OrderType type = OrderType.dineIn,
  OrderStatus status = OrderStatus.received,
  OrderPaymentStatus payment = OrderPaymentStatus.unpaid,
}) {
  return Order(
    id: 'o1',
    orderNumber: 'TEST-001',
    orderType: type,
    subtotal: 100,
    itemDiscountTotal: 0,
    orderDiscountTotal: 0,
    total: 100,
    paymentStatus: payment,
    status: status,
    isPrepaid: false,
    createdByUserId: 'u1',
    createdAt: DateTime(2024, 6, 21),
    updatedAt: DateTime(2024, 6, 21),
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

void main() {
  group('OrderLifecycle', () {
    test('admin can advance dine-in through full chain', () {
      var order = _order(status: OrderStatus.received);
      expect(OrderLifecycle.nextStatus(order), OrderStatus.preparing);

      order = order.copyWith(status: OrderStatus.served);
      expect(OrderLifecycle.nextStatus(order), OrderStatus.paid);
    });

    test('prepaid takeaway skips served and paid status steps', () {
      final order = _order(
        type: OrderType.takeaway,
        status: OrderStatus.ready,
        payment: OrderPaymentStatus.paid,
      );

      expect(OrderLifecycle.nextStatus(order), OrderStatus.completed);
    });

    test('salesman can only advance to ready', () {
      final preparing = _order(status: OrderStatus.preparing);
      expect(OrderLifecycle.canAdvance(preparing, UserRole.salesman), isTrue);

      final ready = _order(status: OrderStatus.ready);
      expect(OrderLifecycle.canAdvance(ready, UserRole.salesman), isFalse);
    });

    test('paid orders cannot be edited', () {
      final paid = _order(payment: OrderPaymentStatus.paid);
      expect(OrderLifecycle.canEdit(paid, UserRole.admin), isFalse);
      expect(
        OrderLifecycle.editBlockedReason(paid),
        contains('read-only'),
      );
    });

    test('only admin can cancel open orders', () {
      final order = _order();
      expect(OrderLifecycle.canCancel(order, UserRole.admin), isTrue);
      expect(OrderLifecycle.canCancel(order, UserRole.salesman), isFalse);
    });

    test('hold and resume toggle operational flag without blocking status', () {
      final order = _order(status: OrderStatus.preparing);
      expect(OrderLifecycle.canHold(order, UserRole.admin), isTrue);
      expect(OrderLifecycle.canResume(order, UserRole.admin), isFalse);

      final held = order.copyWith(isHeld: true);
      expect(OrderLifecycle.canHold(held, UserRole.admin), isFalse);
      expect(OrderLifecycle.canResume(held, UserRole.admin), isTrue);
      expect(OrderLifecycle.nextStatus(held), OrderStatus.ready);
    });

    test('closed orders cannot be held or resumed', () {
      final completed = _order(status: OrderStatus.completed);
      expect(OrderLifecycle.canHold(completed, UserRole.admin), isFalse);
      expect(
        OrderLifecycle.canResume(
          completed.copyWith(isHeld: true),
          UserRole.admin,
        ),
        isFalse,
      );
    });
  });
}
