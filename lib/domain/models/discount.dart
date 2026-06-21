import 'package:uuid/uuid.dart';

/// Where a discount applies in the cart.
enum DiscountScope {
  item,
  category,
  wholeOrder,
}

/// How the discount value is interpreted.
enum DiscountType {
  percentage,
  fixed,
}

/// A discount applied during POS checkout (locked into the order in Module 15).
class AppliedDiscount {
  AppliedDiscount({
    String? id,
    required this.scope,
    this.targetId,
    this.lineId,
    required this.type,
    required this.value,
    this.reason,
  })  : assert(
          scope != DiscountScope.wholeOrder || targetId == null,
          'Whole-order discounts must not have a targetId',
        ),
        assert(
          scope != DiscountScope.item || lineId != null,
          'Item discounts must reference a cart line',
        ),
        assert(
          scope != DiscountScope.category || targetId != null,
          'Category discounts must reference a category',
        ),
        id = id ?? const Uuid().v4();

  final String id;
  final DiscountScope scope;
  final String? targetId;
  final String? lineId;
  final DiscountType type;
  final double value;
  final String? reason;

  AppliedDiscount copyWith({
    DiscountType? type,
    double? value,
    String? reason,
  }) {
    return AppliedDiscount(
      id: id,
      scope: scope,
      targetId: targetId,
      lineId: lineId,
      type: type ?? this.type,
      value: value ?? this.value,
      reason: reason ?? this.reason,
    );
  }
}
