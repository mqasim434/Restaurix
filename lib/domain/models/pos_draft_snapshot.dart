import 'cart_item.dart';
import 'discount.dart';
import 'order_enums.dart';
import 'pos_checkout_draft.dart';

/// Serializable POS session — cart, checkout metadata, and discounts.
/// Payment fields are intentionally excluded; drafts are pre-placement only.
class PosDraftSnapshot {
  const PosDraftSnapshot({
    required this.checkout,
    required this.cartItems,
    required this.discounts,
  });

  final PosCheckoutDraft checkout;
  final List<CartItem> cartItems;
  final List<AppliedDiscount> discounts;

  /// Checkout snapshot without payment — drafts never store payment selection.
  PosCheckoutDraft get checkoutWithoutPayment => PosCheckoutDraft(
        orderType: checkout.orderType,
        tableId: checkout.tableId,
        tableLabel: checkout.tableLabel,
        deliveryMode: checkout.deliveryMode,
        riderId: checkout.riderId,
        riderName: checkout.riderName,
        pickupCompanyId: checkout.pickupCompanyId,
        pickupCompanyName: checkout.pickupCompanyName,
        notes: checkout.notes,
      );

  Map<String, dynamic> toJson() => {
        'checkout': _checkoutToJson(checkoutWithoutPayment),
        'cartItems': cartItems.map(_cartItemToJson).toList(),
        'discounts': discounts.map(_discountToJson).toList(),
      };

  static PosDraftSnapshot fromJson(Map<String, dynamic> json) {
    return PosDraftSnapshot(
      checkout: _checkoutFromJson(json['checkout'] as Map<String, dynamic>),
      cartItems: [
        for (final item in json['cartItems'] as List<dynamic>)
          _cartItemFromJson(item as Map<String, dynamic>),
      ],
      discounts: [
        for (final discount in json['discounts'] as List<dynamic>)
          _discountFromJson(discount as Map<String, dynamic>),
      ],
    );
  }

  static Map<String, dynamic> _checkoutToJson(PosCheckoutDraft draft) => {
        'orderType': draft.orderType?.wireValue,
        'tableId': draft.tableId,
        'tableLabel': draft.tableLabel,
        'deliveryMode': draft.deliveryMode?.wireValue,
        'riderId': draft.riderId,
        'riderName': draft.riderName,
        'pickupCompanyId': draft.pickupCompanyId,
        'pickupCompanyName': draft.pickupCompanyName,
        'notes': draft.notes,
      };

  static PosCheckoutDraft _checkoutFromJson(Map<String, dynamic> json) {
    OrderType? orderType;
    final orderTypeValue = json['orderType'] as String?;
    if (orderTypeValue != null) {
      orderType = OrderType.values.firstWhere(
        (type) => type.wireValue == orderTypeValue,
      );
    }

    DeliveryMode? deliveryMode;
    final deliveryModeValue = json['deliveryMode'] as String?;
    if (deliveryModeValue != null) {
      deliveryMode = DeliveryMode.values.firstWhere(
        (mode) => mode.wireValue == deliveryModeValue,
      );
    }

    return PosCheckoutDraft(
      orderType: orderType,
      tableId: json['tableId'] as String?,
      tableLabel: json['tableLabel'] as String?,
      deliveryMode: deliveryMode,
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      pickupCompanyId: json['pickupCompanyId'] as String?,
      pickupCompanyName: json['pickupCompanyName'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static Map<String, dynamic> _cartItemToJson(CartItem item) => {
        'lineId': item.lineId,
        'productId': item.productId,
        'dealId': item.dealId,
        'categoryId': item.categoryId,
        'name': item.name,
        'unitPrice': item.unitPrice,
        'variantId': item.variantId,
        'variantName': item.variantName,
        'variantPriceOverride': item.variantPriceOverride,
        'quantity': item.quantity,
        'modifiers': [
          for (final modifier in item.modifiers)
            {
              'id': modifier.id,
              'groupId': modifier.groupId,
              'name': modifier.name,
              'priceDelta': modifier.priceDelta,
            },
        ],
      };

  static CartItem _cartItemFromJson(Map<String, dynamic> json) {
    return CartItem(
      lineId: json['lineId'] as String,
      productId: json['productId'] as String?,
      dealId: json['dealId'] as String?,
      categoryId: json['categoryId'] as String?,
      name: json['name'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      variantId: json['variantId'] as String?,
      variantName: json['variantName'] as String?,
      variantPriceOverride: (json['variantPriceOverride'] as num?)?.toDouble(),
      quantity: json['quantity'] as int,
      modifiers: [
        for (final modifier in json['modifiers'] as List<dynamic>)
          CartModifier(
            id: modifier['id'] as String,
            groupId: modifier['groupId'] as String,
            name: modifier['name'] as String,
            priceDelta: (modifier['priceDelta'] as num).toDouble(),
          ),
      ],
    );
  }

  static Map<String, dynamic> _discountToJson(AppliedDiscount discount) => {
        'id': discount.id,
        'scope': discount.scope.name,
        'targetId': discount.targetId,
        'lineId': discount.lineId,
        'type': discount.type.name,
        'value': discount.value,
        'reason': discount.reason,
      };

  static AppliedDiscount _discountFromJson(Map<String, dynamic> json) {
    return AppliedDiscount(
      id: json['id'] as String,
      scope: DiscountScope.values.byName(json['scope'] as String),
      targetId: json['targetId'] as String?,
      lineId: json['lineId'] as String?,
      type: DiscountType.values.byName(json['type'] as String),
      value: (json['value'] as num).toDouble(),
      reason: json['reason'] as String?,
    );
  }
}
