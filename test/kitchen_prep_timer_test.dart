import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/order_item.dart';
import 'package:restaurix/domain/services/kitchen_prep_resolver.dart';
import 'package:restaurix/domain/models/cart_item.dart';
import 'package:restaurix/domain/services/kitchen_prep_timer.dart';

OrderItem _item({
  KitchenStatus status = KitchenStatus.received,
  int prepMinutes = 10,
  required DateTime changedAt,
}) {
  return OrderItem(
    id: 'i1',
    orderId: 'o1',
    name: 'Burger',
    unitPrice: 10,
    quantity: 1,
    lineTotal: 10,
    kitchenStatus: status,
    prepMinutes: prepMinutes,
    kitchenStatusChangedAt: changedAt,
    createdAt: changedAt,
    updatedAt: changedAt,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

void main() {
  group('KitchenPrepResolver', () {
    test('order override replaces product prep minutes', () {
      final minutes = KitchenPrepResolver.resolveItemPrepMinutes(
        item: CartItem(
          lineId: 'l1',
          productId: 'p1',
          name: 'Burger',
          unitPrice: 10,
          quantity: 1,
        ),
        orderPromisedPrepMinutes: 20,
        productPrepMinutesById: {'p1': 8},
      );

      expect(minutes, 20);
    });

    test('uses product prep when no order override', () {
      final minutes = KitchenPrepResolver.resolveItemPrepMinutes(
        item: CartItem(
          lineId: 'l1',
          productId: 'p1',
          name: 'Burger',
          unitPrice: 10,
          quantity: 1,
        ),
        orderPromisedPrepMinutes: null,
        productPrepMinutesById: {'p1': 8},
      );

      expect(minutes, 8);
    });
  });

  group('KitchenPrepTimer', () {
    test('advances received item after incoming stage elapses', () {
      final changedAt = DateTime(2024, 6, 21, 12, 0);
      final item = _item(
        status: KitchenStatus.received,
        prepMinutes: 4,
        changedAt: changedAt,
      );

      expect(
        KitchenPrepTimer.dueAdvanceStatus(
          item: item,
          now: changedAt.add(const Duration(minutes: 2)),
          orderIsHeld: false,
        ),
        KitchenStatus.preparing,
      );
    });

    test('held orders do not auto-advance', () {
      final changedAt = DateTime(2024, 6, 21, 12, 0);
      final item = _item(status: KitchenStatus.received, changedAt: changedAt);

      expect(
        KitchenPrepTimer.dueAdvanceStatus(
          item: item,
          now: changedAt.add(const Duration(minutes: 30)),
          orderIsHeld: true,
        ),
        isNull,
      );
    });

    test('one-minute prep does not throw when splitting stages', () {
      expect(KitchenPrepTimer.incomingStageMinutes(1), 1);
      expect(KitchenPrepTimer.preparingStageMinutes(1), 0);

      final changedAt = DateTime(2024, 6, 21, 12, 0);
      final item = _item(
        status: KitchenStatus.received,
        prepMinutes: 1,
        changedAt: changedAt,
      );

      expect(
        KitchenPrepTimer.dueAdvanceStatus(
          item: item,
          now: changedAt.add(const Duration(minutes: 1)),
          orderIsHeld: false,
        ),
        KitchenStatus.preparing,
      );
    });
  });
}
