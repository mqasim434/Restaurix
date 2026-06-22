import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/order_item.dart';
import 'package:restaurix/domain/services/kitchen_lifecycle.dart';

Order _order({
  String id = 'o1',
  OrderStatus status = OrderStatus.received,
  OrderType type = OrderType.dineIn,
  String? tableId,
  bool isHeld = false,
}) {
  return Order(
    id: id,
    orderNumber: 'DEV-001',
    orderType: type,
    tableId: tableId,
    subtotal: 100,
    itemDiscountTotal: 0,
    orderDiscountTotal: 0,
    total: 100,
    paymentStatus: OrderPaymentStatus.unpaid,
    status: status,
    isPrepaid: false,
    isHeld: isHeld,
    createdByUserId: 'u1',
    createdAt: DateTime(2024, 6, 21, 12),
    updatedAt: DateTime(2024, 6, 21, 12),
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

OrderItem _item({
  String id = 'i1',
  String orderId = 'o1',
  KitchenStatus kitchenStatus = KitchenStatus.received,
  String name = 'Burger',
}) {
  return OrderItem(
    id: id,
    orderId: orderId,
    name: name,
    unitPrice: 10,
    quantity: 1,
    lineTotal: 10,
    kitchenStatus: kitchenStatus,
    createdAt: DateTime(2024, 6, 21, 12),
    updatedAt: DateTime(2024, 6, 21, 12),
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

void main() {
  group('KitchenLifecycle', () {
    test('cancelled and completed orders are hidden from kitchen', () {
      expect(
        KitchenLifecycle.isOrderVisibleOnKitchen(
          _order(status: OrderStatus.cancelled),
        ),
        isFalse,
      );
      expect(
        KitchenLifecycle.isOrderVisibleOnKitchen(
          _order(status: OrderStatus.completed),
        ),
        isFalse,
      );
      expect(
        KitchenLifecycle.isOrderVisibleOnKitchen(
          _order(status: OrderStatus.preparing),
        ),
        isTrue,
      );
    });

    test('items advance received to preparing to ready only', () {
      expect(
        KitchenLifecycle.nextItemStatus(KitchenStatus.received),
        KitchenStatus.preparing,
      );
      expect(
        KitchenLifecycle.nextItemStatus(KitchenStatus.preparing),
        KitchenStatus.ready,
      );
      expect(KitchenLifecycle.nextItemStatus(KitchenStatus.ready), isNull);
    });

    test('mixed item pace splits cards across columns', () {
      final order = _order(tableId: 't1');
      final items = [
        _item(id: 'i1', kitchenStatus: KitchenStatus.received, name: 'Grill'),
        _item(id: 'i2', kitchenStatus: KitchenStatus.preparing, name: 'Salad'),
      ];

      final board = KitchenLifecycle.buildBoard(
        orders: [order],
        itemsByOrderId: {order.id: items},
        tableLabelsById: {'t1': '5'},
      );

      expect(board.incoming, hasLength(1));
      expect(board.incoming.first.items, hasLength(1));
      expect(board.incoming.first.items.first.name, 'Grill');
      expect(board.preparing, hasLength(1));
      expect(board.preparing.first.items.first.name, 'Salad');
      expect(board.ready, isEmpty);
      expect(board.incoming.first.contextLabel, 'Table 5');
    });

    test('derive order preparing when any item started', () {
      final order = _order(status: OrderStatus.received);
      final items = [
        _item(kitchenStatus: KitchenStatus.received),
        _item(id: 'i2', kitchenStatus: KitchenStatus.preparing),
      ];

      expect(
        KitchenLifecycle.deriveOrderStatus(order, items),
        OrderStatus.preparing,
      );
    });

    test('derive order ready when all items ready', () {
      final order = _order(status: OrderStatus.preparing);
      final items = [
        _item(kitchenStatus: KitchenStatus.ready),
        _item(id: 'i2', kitchenStatus: KitchenStatus.ready),
      ];

      expect(
        KitchenLifecycle.deriveOrderStatus(order, items),
        OrderStatus.ready,
      );
    });

    test('held cards sort before non-held within a column', () {
      final held = _order(id: 'held', isHeld: true);
      final normal = _order(
        id: 'normal',
        isHeld: false,
        status: OrderStatus.received,
      );

      final board = KitchenLifecycle.buildBoard(
        orders: [normal, held],
        itemsByOrderId: {
          held.id: [_item(orderId: held.id)],
          normal.id: [_item(orderId: normal.id, id: 'i2')],
        },
        tableLabelsById: const {},
      );

      expect(board.incoming.first.orderId, held.id);
    });

    test('board excludes served kitchen items', () {
      final order = _order();
      final items = [_item(kitchenStatus: KitchenStatus.served)];

      final board = KitchenLifecycle.buildBoard(
        orders: [order],
        itemsByOrderId: {order.id: items},
        tableLabelsById: const {},
      );

      expect(board.incoming, isEmpty);
      expect(board.preparing, isEmpty);
      expect(board.ready, isEmpty);
    });
  });
}
