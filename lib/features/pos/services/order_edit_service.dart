import 'package:uuid/uuid.dart';

import '../../../domain/models/cart_item.dart';
import '../../../domain/models/discount.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/models/pos_checkout_draft.dart';
import '../../../data/local/mappers/order_mapper.dart';

class OrderEditSnapshot {
  const OrderEditSnapshot({
    required this.orderId,
    required this.checkout,
    required this.cartItems,
    required this.discounts,
  });

  final String orderId;
  final PosCheckoutDraft checkout;
  final List<CartItem> cartItems;
  final List<AppliedDiscount> discounts;
}

OrderEditSnapshot buildOrderEditSnapshot({
  required Order order,
  required List<OrderItem> items,
  required Map<String, String?> productCategoryIds,
}) {
  final cartItems = <CartItem>[];
  final discounts = <AppliedDiscount>[];
  final seenCategoryTargets = <String>{};

  for (final item in items) {
    final lineId = const Uuid().v4();
    cartItems.add(
      CartItem(
        lineId: lineId,
        productId: item.productId,
        dealId: item.dealId,
        categoryId: item.productId != null
            ? productCategoryIds[item.productId!]
            : null,
        name: item.name,
        unitPrice: item.unitPrice,
        variantName: item.variantName,
        modifiers: [
          for (final modifier in item.modifiers)
            CartModifier(
              id: modifier.modifierId ?? const Uuid().v4(),
              groupId: '',
              name: modifier.name,
              priceDelta: modifier.priceDelta,
            ),
        ],
        quantity: item.quantity,
      ),
    );

    for (final discount in item.appliedDiscounts) {
      if (discount.scope == DiscountScope.item) {
        discounts.add(
          AppliedDiscount(
            scope: DiscountScope.item,
            targetId: item.productId ?? item.dealId,
            lineId: lineId,
            type: discount.type,
            value: discount.value,
            reason: discount.reason,
          ),
        );
      } else if (discount.scope == DiscountScope.category &&
          discount.targetId != null &&
          !seenCategoryTargets.contains(discount.targetId)) {
        seenCategoryTargets.add(discount.targetId!);
        discounts.add(
          AppliedDiscount(
            scope: DiscountScope.category,
            targetId: discount.targetId,
            type: discount.type,
            value: discount.value,
            reason: discount.reason,
          ),
        );
      }
    }
  }

  final wholeOrder = wholeOrderDiscountFromOrder(order);
  if (wholeOrder != null) {
    discounts.add(wholeOrder);
  }

  final checkout = PosCheckoutDraft(
    orderType: order.orderType,
    tableId: order.tableId,
    deliveryMode: order.deliveryMode,
    riderId: order.riderId,
    riderName: order.riderName,
    pickupCompanyId: order.pickupCompanyId,
    pickupCompanyName: order.pickupCompanyName,
    paymentType: order.paymentType,
    isPrepaidOverride: order.isPrepaid,
    notes: order.notes,
  );

  return OrderEditSnapshot(
    orderId: order.id,
    checkout: checkout,
    cartItems: cartItems,
    discounts: discounts,
  );
}
