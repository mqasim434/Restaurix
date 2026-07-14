import 'package:uuid/uuid.dart';

/// Transient cart line — persisted in [CartNotifier] until checkout.
class CartItem {
  CartItem({
    String? lineId,
    this.productId,
    this.dealId,
    this.categoryId,
    required this.name,
    required this.unitPrice,
    this.variantId,
    this.variantName,
    this.variantPriceOverride,
    this.quantity = 1,
  })  : assert(productId != null || dealId != null,
            'Cart item must reference a product or deal'),
        assert(productId == null || dealId == null,
            'Cart item cannot reference both product and deal'),
        lineId = lineId ?? const Uuid().v4();

  final String lineId;
  final String? productId;
  final String? dealId;
  final String? categoryId;
  final String name;
  final double unitPrice;
  final String? variantId;
  final String? variantName;
  final double? variantPriceOverride;
  final int quantity;

  bool get isDeal => dealId != null;

  double get lineTotal => unitPrice * quantity;

  /// Same product/deal and variant — used to merge quantity.
  bool matchesConfiguration(CartItem other) {
    if (productId != other.productId || dealId != other.dealId) return false;
    return variantId == other.variantId;
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      lineId: lineId,
      productId: productId,
      dealId: dealId,
      categoryId: categoryId,
      name: name,
      unitPrice: unitPrice,
      variantId: variantId,
      variantName: variantName,
      variantPriceOverride: variantPriceOverride,
      quantity: quantity ?? this.quantity,
    );
  }
}

double computeCartUnitPrice({
  required double basePrice,
  double? variantPrice,
}) {
  return variantPrice ?? basePrice;
}
