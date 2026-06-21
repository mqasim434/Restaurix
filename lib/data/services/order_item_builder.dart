import 'package:uuid/uuid.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/discount.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/order_enums.dart';
import '../../features/pos/services/discount_calculator.dart';

/// Builds persisted order line snapshots from cart + discount state.
List<OrderItem> buildOrderItems({
  required String orderId,
  required List<CartItem> cartItems,
  required List<AppliedDiscount> discounts,
  required CartPricingBreakdown pricing,
  required String deviceId,
  required DateTime now,
}) {
  return [
    for (final item in cartItems)
      OrderItem(
        id: const Uuid().v4(),
        orderId: orderId,
        productId: item.productId,
        dealId: item.dealId,
        name: item.name,
        variantName: item.variantName,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        lineTotal: pricing.linePricing[item.lineId]?.netTotal ?? item.lineTotal,
        modifiers: [
          for (final modifier in item.modifiers)
            OrderItemModifier(
              modifierId: modifier.id,
              name: modifier.name,
              priceDelta: modifier.priceDelta,
            ),
        ],
        appliedDiscounts: _lineDiscounts(
          item: item,
          discounts: discounts,
          linePricing: pricing.linePricing[item.lineId],
        ),
        kitchenStatus: KitchenStatus.received,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
        syncAction: SyncAction.create,
        deviceId: deviceId,
        version: 1,
      ),
  ];
}

List<OrderLineDiscount> _lineDiscounts({
  required CartItem item,
  required List<AppliedDiscount> discounts,
  required LinePricing? linePricing,
}) {
  if (linePricing == null || linePricing.lineDiscountAmount <= 0) {
    return const [];
  }

  final result = <OrderLineDiscount>[];
  var remainingItem = linePricing.itemDiscountAmount;
  var remainingCategory = linePricing.categoryDiscountAmount;

  for (final discount in discounts.where(
    (d) => d.scope == DiscountScope.item && d.lineId == item.lineId,
  )) {
    final amount = _singleDiscountAmount(
      base: item.lineTotal,
      type: discount.type,
      value: discount.value,
      cap: remainingItem,
    );
    if (amount > 0) {
      result.add(
        OrderLineDiscount(
          scope: discount.scope,
          type: discount.type,
          value: discount.value,
          amountApplied: amount,
          targetId: discount.targetId,
          reason: discount.reason,
        ),
      );
      remainingItem -= amount;
    }
  }

  if (item.categoryId == null) return result;

  var categoryBase = item.lineTotal;
  for (final discount in discounts.where(
    (d) => d.scope == DiscountScope.item && d.lineId == item.lineId,
  )) {
    categoryBase -= _singleDiscountAmount(
      base: item.lineTotal,
      type: discount.type,
      value: discount.value,
      cap: linePricing.itemDiscountAmount,
    );
  }

  for (final discount in discounts.where(
    (d) =>
        d.scope == DiscountScope.category &&
        d.targetId == item.categoryId,
  )) {
    final amount = _singleDiscountAmount(
      base: categoryBase,
      type: discount.type,
      value: discount.value,
      cap: remainingCategory,
    );
    if (amount > 0) {
      result.add(
        OrderLineDiscount(
          scope: discount.scope,
          type: discount.type,
          value: discount.value,
          amountApplied: amount,
          targetId: discount.targetId,
          reason: discount.reason,
        ),
      );
      remainingCategory -= amount;
      categoryBase -= amount;
    }
  }

  return result;
}

double _singleDiscountAmount({
  required double base,
  required DiscountType type,
  required double value,
  required double cap,
}) {
  if (base <= 0 || value <= 0 || cap <= 0) return 0;

  final raw = switch (type) {
    DiscountType.percentage => base * (value / 100),
    DiscountType.fixed => value,
  };

  return raw.clamp(0, cap.clamp(0, base)).toDouble();
}
