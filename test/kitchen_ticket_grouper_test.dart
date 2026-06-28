import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/order_item.dart';
import 'package:restaurix/features/printing/kitchen_ticket/kitchen_ticket_grouper.dart';
import 'package:restaurix/features/printing/kitchen_ticket/kitchen_ticket_preview.dart';
import 'package:restaurix/features/printing/kitchen_ticket/product_kitchen_meta.dart';

String? _identityResolver(String? reference) => reference;

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
    modifiers: const [],
  );
}

void main() {
  group('KitchenTicketGrouper', () {
    test('splits jobs by printer target', () {
      final jobs = KitchenTicketGrouper.buildPrintJobs(
        order: _order(),
        items: [
          _item(id: 'i1', productId: 'p1', name: 'Burger'),
          _item(id: 'i2', productId: 'p2', name: 'Cola'),
        ],
        productMetaById: const {
          'p1': ProductKitchenMeta(
            kitchenCategory: 'Grill',
            printerId: '192.168.1.10',
          ),
          'p2': ProductKitchenMeta(
            kitchenCategory: 'Bar',
            printerId: '192.168.1.20',
          ),
        },
        defaultPrinterId: null,
        categoryPrinterMap: const {},
        resolveTarget: _identityResolver,
        isReprint: false,
        contextLabel: 'Table 5',
      );

      expect(jobs, hasLength(2));
      expect(jobs.map((job) => job.printerTarget).toSet(), {
        '192.168.1.10',
        '192.168.1.20',
      });
    });

    test('groups lines by kitchen category within a ticket', () {
      final jobs = KitchenTicketGrouper.buildPrintJobs(
        order: _order(),
        items: [
          _item(id: 'i1', productId: 'p1', name: 'Steak'),
          _item(id: 'i2', productId: 'p2', name: 'Salad'),
        ],
        productMetaById: const {
          'p1': ProductKitchenMeta(
            kitchenCategory: 'Grill',
            printerId: 'Kitchen',
          ),
          'p2': ProductKitchenMeta(
            kitchenCategory: 'Cold',
            printerId: 'Kitchen',
          ),
        },
        defaultPrinterId: null,
        categoryPrinterMap: const {},
        resolveTarget: _identityResolver,
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
          'p1': ProductKitchenMeta(printerId: 'Kitchen'),
        },
        defaultPrinterId: null,
        categoryPrinterMap: const {},
        resolveTarget: _identityResolver,
        isReprint: true,
        contextLabel: 'Table 5',
      );

      final preview = KitchenTicketPreview.renderLines(jobs.first.ticket);
      expect(preview.first, '*** REPRINT ***');
    });

    test('routes by kitchen category when product has no printer', () {
      final jobs = KitchenTicketGrouper.buildPrintJobs(
        order: _order(),
        items: [_item(productId: 'p1', name: 'Cola')],
        productMetaById: const {
          'p1': ProductKitchenMeta(kitchenCategory: 'Bar'),
        },
        defaultPrinterId: null,
        categoryPrinterMap: const {'Bar': 'bar-printer-id'},
        resolveTarget: (reference) => switch (reference) {
          'bar-printer-id' => '192.168.1.20',
          _ => reference,
        },
        isReprint: false,
        contextLabel: 'Table 5',
      );

      expect(jobs, hasLength(1));
      expect(jobs.first.printerTarget, '192.168.1.20');
    });

    test('warns when no printer can be resolved', () {
      final warnings = KitchenTicketGrouper.collectMissingPrinterWarnings(
        items: [_item(productId: 'p1')],
        productMetaById: const {'p1': ProductKitchenMeta()},
        defaultPrinterId: null,
        categoryPrinterMap: const {},
        resolveTarget: _identityResolver,
      );

      expect(warnings, isNotEmpty);
    });
  });
}
