import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/order_item.dart';
import 'package:restaurix/features/printing/receipt/receipt_builder.dart';
import 'package:restaurix/features/printing/receipt/receipt_preview.dart';

Order _order({
  OrderPaymentStatus payment = OrderPaymentStatus.unpaid,
  double subtotal = 100,
  double itemDiscountTotal = 10,
  double orderDiscountTotal = 5,
  double total = 85,
}) {
  return Order(
    id: 'o1',
    orderNumber: 'DEV-001',
    orderType: OrderType.takeaway,
    subtotal: subtotal,
    itemDiscountTotal: itemDiscountTotal,
    orderDiscountTotal: orderDiscountTotal,
    total: total,
    paymentStatus: payment,
    status: OrderStatus.received,
    isPrepaid: payment.isSettled,
    createdByUserId: 'u1',
    paymentType: PaymentType.cash,
    createdAt: DateTime(2024, 6, 21, 12, 30),
    updatedAt: DateTime(2024, 6, 21, 12, 30),
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

OrderItem _item() {
  final now = DateTime(2024, 6, 21, 12, 30);
  return OrderItem(
    id: 'i1',
    orderId: 'o1',
    name: 'Burger',
    unitPrice: 50,
    quantity: 2,
    lineTotal: 90,
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
  group('ReceiptBuilder', () {
    test('uses persisted order totals without recalculation', () {
      final receipt = ReceiptBuilder.fromPersisted(
        order: _order(),
        items: [_item()],
        businessName: 'Restaurix',
        tableLabelsById: const {},
        currencyCode: 'USD',
      );

      expect(receipt.subtotal, 100);
      expect(receipt.itemDiscountTotal, 10);
      expect(receipt.orderDiscountTotal, 5);
      expect(receipt.total, 85);
      expect(receipt.lines.single.lineTotal, 90);
    });

    test('reprint banner appears in preview', () {
      final receipt = ReceiptBuilder.fromPersisted(
        order: _order(payment: OrderPaymentStatus.paid),
        items: [_item()],
        businessName: 'Restaurix',
        tableLabelsById: const {},
        currencyCode: 'USD',
        isReprint: true,
      );

      final lines = ReceiptPreview.renderLines(receipt);
      expect(lines.first, '*** REPRINT ***');
      expect(lines.contains('[LOGO]'), isTrue);
      expect(lines.any((line) => line.startsWith('TOTAL:')), isTrue);
    });
  });

  group('ReceiptPrintPolicy', () {
    test('auto prints only when payment is settled', () {
      expect(
        ReceiptPrintPolicy.shouldAutoPrint(
          _order(payment: OrderPaymentStatus.paid),
        ),
        isTrue,
      );
      expect(
        ReceiptPrintPolicy.shouldAutoPrint(
          _order(payment: OrderPaymentStatus.unpaid),
        ),
        isFalse,
      );
    });

    test('never auto prints cancelled orders', () {
      final cancelled = _order(payment: OrderPaymentStatus.paid).copyWith(
        status: OrderStatus.cancelled,
      );
      expect(ReceiptPrintPolicy.shouldAutoPrint(cancelled), isFalse);
    });
  });
}
