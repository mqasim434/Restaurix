import 'package:uuid/uuid.dart';

/// Snapshot of a selected modifier at add-to-cart time.
class CartModifier {
  const CartModifier({
    required this.id,
    required this.groupId,
    required this.name,
    required this.priceDelta,
  });

  final String id;
  final String groupId;
  final String name;
  final double priceDelta;
}

/// Transient cart line — persisted in [CartNotifier] until checkout (Module 15).
class CartItem {
  CartItem({
    String? lineId,
    this.productId,
    this.dealId,
    required this.name,
    required this.unitPrice,
    this.variantId,
    this.variantName,
    this.variantPriceOverride,
    this.modifiers = const [],
    this.quantity = 1,
  })  : assert(productId != null || dealId != null,
            'Cart item must reference a product or deal'),
        assert(productId == null || dealId == null,
            'Cart item cannot reference both product and deal'),
        lineId = lineId ?? const Uuid().v4();

  final String lineId;
  final String? productId;
  final String? dealId;
  final String name;
  final double unitPrice;
  final String? variantId;
  final String? variantName;
  final double? variantPriceOverride;
  final List<CartModifier> modifiers;
  final int quantity;

  bool get isDeal => dealId != null;

  double get lineTotal => unitPrice * quantity;

  /// Same product/deal, variant, and modifier set — used to merge quantity.
  bool matchesConfiguration(CartItem other) {
    if (productId != other.productId || dealId != other.dealId) return false;
    if (variantId != other.variantId) return false;

    final a = modifiers.map((m) => m.id).toList()..sort();
    final b = other.modifiers.map((m) => m.id).toList()..sort();
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      lineId: lineId,
      productId: productId,
      dealId: dealId,
      name: name,
      unitPrice: unitPrice,
      variantId: variantId,
      variantName: variantName,
      variantPriceOverride: variantPriceOverride,
      modifiers: modifiers,
      quantity: quantity ?? this.quantity,
    );
  }
}

double computeCartUnitPrice({
  required double basePrice,
  double? variantPrice,
  List<CartModifier> modifiers = const [],
}) {
  final itemPrice = variantPrice ?? basePrice;
  final modifierTotal =
      modifiers.fold(0.0, (sum, modifier) => sum + modifier.priceDelta);
  return itemPrice + modifierTotal;
}
