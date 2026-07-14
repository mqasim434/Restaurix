import 'package:restaurix/domain/models/cart_item.dart';
import 'package:restaurix/domain/models/discount.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/pos_checkout_draft.dart';
import 'package:restaurix/domain/models/pos_draft_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PosDraftSnapshot', () {
    test('round-trips cart, checkout, and discounts without payment', () {
      final snapshot = PosDraftSnapshot(
        checkout: PosCheckoutDraft(
          orderType: OrderType.dineIn,
          tableId: 'table-1',
          tableLabel: 'T5',
          paymentType: PaymentType.cash,
          notes: 'No ice',
        ),
        cartItems: [
          CartItem(
            lineId: 'line-1',
            productId: 'prod-1',
            categoryId: 'cat-1',
            name: 'Burger',
            unitPrice: 500,
            quantity: 2,
          ),
        ],
        discounts: [
          AppliedDiscount(
            scope: DiscountScope.item,
            targetId: 'prod-1',
            lineId: 'line-1',
            type: DiscountType.percentage,
            value: 10,
          ),
        ],
      );

      final restored = PosDraftSnapshot.fromJson(snapshot.toJson());

      expect(restored.cartItems.length, 1);
      expect(restored.cartItems.first.name, 'Burger');
      expect(restored.cartItems.first.quantity, 2);
      expect(restored.checkout.orderType, OrderType.dineIn);
      expect(restored.checkout.tableLabel, 'T5');
      expect(restored.checkout.notes, 'No ice');
      expect(restored.checkout.paymentType, isNull);
      expect(restored.discounts.first.value, 10);
    });
  });
}
