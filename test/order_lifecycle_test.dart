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
  bool isPrepaid = false,
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
    isPrepaid: isPrepaid,
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
      expect(OrderLifecycle.nextStatus(order), OrderStatus.served);

      order = order.copyWith(status: OrderStatus.served);
      expect(OrderLifecycle.nextStatus(order), OrderStatus.paid);

      order = order.copyWith(
        status: OrderStatus.paid,
        paymentStatus: OrderPaymentStatus.paid,
      );
      expect(OrderLifecycle.nextStatus(order), OrderStatus.completed);
    });

    test('prepaid takeaway skips payment step', () {
      final order = _order(
        type: OrderType.takeaway,
        status: OrderStatus.received,
        payment: OrderPaymentStatus.paid,
        isPrepaid: true,
      );

      expect(OrderLifecycle.nextStatus(order), OrderStatus.completed);
    });

    test('salesman can mark dine-in served only', () {
      final received = _order(status: OrderStatus.received);
      expect(OrderLifecycle.canAdvance(received, UserRole.salesman), isTrue);

      final served = _order(status: OrderStatus.served);
      expect(OrderLifecycle.canAdvance(served, UserRole.salesman), isFalse);
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
      final order = _order(status: OrderStatus.received);
      expect(OrderLifecycle.canHold(order, UserRole.admin), isTrue);
      expect(OrderLifecycle.canResume(order, UserRole.admin), isFalse);

      final held = order.copyWith(isHeld: true);
      expect(OrderLifecycle.canHold(held, UserRole.admin), isFalse);
      expect(OrderLifecycle.canResume(held, UserRole.admin), isTrue);
      expect(OrderLifecycle.nextStatus(held), OrderStatus.served);
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
