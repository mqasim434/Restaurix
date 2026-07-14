import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/order_item.dart';
import 'package:restaurix/features/printing/kitchen_ticket/kitchen_ticket_grouper.dart';
import 'package:restaurix/features/printing/kitchen_ticket/kitchen_ticket_preview.dart';
import 'package:restaurix/features/printing/kitchen_ticket/product_kitchen_meta.dart';
import 'package:restaurix/features/printing/system_printer.dart';

Order _order() {
  return Order(
    id: 'o1',
    orderNumber: 'DEV-001',
    orderType: OrderType.dineIn,
    tableId: 't1',
    subtotal: 100,
    itemDiscountTotal: 0,
    orderDiscountTotal: 0,
    total: 100,
    paymentStatus: OrderPaymentStatus.unpaid,
    status: OrderStatus.received,
    isPrepaid: false,
    createdByUserId: 'u1',
    notes: 'No onions',
    createdAt: DateTime(2024, 6, 21, 12, 30),
    updatedAt: DateTime(2024, 6, 21, 12, 30),
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

OrderItem _item({
  String id = 'i1',
  String? productId = 'p1',
  String name = 'Burger',
}) {
  final now = DateTime(2024, 6, 21, 12, 30);
  return OrderItem(
    id: id,
    orderId: 'o1',
    productId: productId,
    name: name,
    unitPrice: 10,
    quantity: 2,
    lineTotal: 20,
    kitchenStatus: KitchenStatus.received,
    kitchenStatusChangedAt: now,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

void main() {
  group('KitchenTicketGrouper', () {
    test('prints all items on the system default printer', () {
      final jobs = KitchenTicketGrouper.buildPrintJobs(
        order: _order(),
        items: [
          _item(id: 'i1', productId: 'p1', name: 'Burger'),
          _item(id: 'i2', productId: 'p2', name: 'Cola'),
        ],
        productMetaById: const {
          'p1': ProductKitchenMeta(kitchenCategory: 'Grill'),
          'p2': ProductKitchenMeta(kitchenCategory: 'Bar'),
        },
        isReprint: false,
        contextLabel: 'Table 5',
      );

      expect(jobs, hasLength(1));
      expect(jobs.first.printerTarget, SystemPrinter.defaultTarget);
    });

    test('groups lines by kitchen category within a ticket', () {
      final jobs = KitchenTicketGrouper.buildPrintJobs(
        order: _order(),
        items: [
          _item(id: 'i1', productId: 'p1', name: 'Steak'),
          _item(id: 'i2', productId: 'p2', name: 'Salad'),
        ],
        productMetaById: const {
          'p1': ProductKitchenMeta(kitchenCategory: 'Grill'),
          'p2': ProductKitchenMeta(kitchenCategory: 'Cold'),
        },
        isReprint: false,
        contextLabel: 'Table 5',
      );

      expect(jobs, hasLength(1));
      expect(jobs.first.ticket.categoryGroups, hasLength(2));
      final preview = KitchenTicketPreview.renderLines(jobs.first.ticket);
      expect(preview.any((line) => line.contains('GRILL')), isTrue);
      expect(preview.any((line) => line.contains('COLD')), isTrue);
      expect(preview.any((line) => line.contains('\$')), isFalse);
    });

    test('marks reprints clearly in preview', () {
      final jobs = KitchenTicketGrouper.buildPrintJobs(
        order: _order(),
        items: [_item()],
        productMetaById: const {
          'p1': ProductKitchenMeta(kitchenCategory: 'Grill'),
        },
        isReprint: true,
        contextLabel: 'Table 5',
      );

      final preview = KitchenTicketPreview.renderLines(jobs.first.ticket);
      expect(preview.first, '*** REPRINT ***');
    });
  });
}
