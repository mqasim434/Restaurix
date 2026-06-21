import '../../../domain/models/cart_item.dart';
import '../../../domain/models/discount.dart';

/// Per-line pricing after discounts.
class LinePricing {
  const LinePricing({
    required this.grossTotal,
    required this.itemDiscountAmount,
    required this.categoryDiscountAmount,
    required this.netTotal,
  });

  final double grossTotal;
  final double itemDiscountAmount;
  final double categoryDiscountAmount;
  final double netTotal;

  double get lineDiscountAmount => itemDiscountAmount + categoryDiscountAmount;
}

/// Full cart pricing with a visible discount breakdown.
class CartPricingBreakdown {
  const CartPricingBreakdown({
    required this.subtotal,
    required this.lineDiscountTotal,
    required this.orderDiscountTotal,
    required this.total,
    required this.linePricing,
    this.warnings = const [],
  });

  final double subtotal;
  final double lineDiscountTotal;
  final double orderDiscountTotal;
  final double total;
  final Map<String, LinePricing> linePricing;
  final List<String> warnings;

  double get subtotalAfterLineDiscounts => subtotal - lineDiscountTotal;

  bool get hasDiscounts =>
      lineDiscountTotal > 0 || orderDiscountTotal > 0;
}

/// Computes stacked discounts in a fixed order:
///
/// 1. Item-scoped discounts on each line (gross line total).
/// 2. Category-scoped discounts on the post-item line total.
/// 3. Whole-order discounts on the resulting subtotal.
///
/// Percentage values are 0–100. Line and order totals never go below zero.
class DiscountCalculator {
  static CartPricingBreakdown compute({
    required List<CartItem> items,
    required List<AppliedDiscount> discounts,
  }) {
    final warnings = <String>[];
    final linePricing = <String, LinePricing>{};

    var subtotal = 0.0;
    var lineDiscountTotal = 0.0;

    for (final item in items) {
      final gross = item.lineTotal;
      subtotal += gross;

      var afterItem = gross;
      var itemDiscountAmount = 0.0;

      for (final discount in discounts.where(
        (d) => d.scope == DiscountScope.item && d.lineId == item.lineId,
      )) {
        final result = _applyDiscount(
          amount: afterItem,
          type: discount.type,
          value: discount.value,
          label: 'Item discount',
          warnings: warnings,
        );
        itemDiscountAmount += result.reduction;
        afterItem = result.amount;
      }

      var afterCategory = afterItem;
      var categoryDiscountAmount = 0.0;

      if (item.categoryId != null) {
        for (final discount in discounts.where(
          (d) =>
              d.scope == DiscountScope.category &&
              d.targetId == item.categoryId,
        )) {
          final result = _applyDiscount(
            amount: afterCategory,
            type: discount.type,
            value: discount.value,
            label: 'Category discount',
            warnings: warnings,
          );
          categoryDiscountAmount += result.reduction;
          afterCategory = result.amount;
        }
      }

      lineDiscountTotal += itemDiscountAmount + categoryDiscountAmount;

      linePricing[item.lineId] = LinePricing(
        grossTotal: gross,
        itemDiscountAmount: itemDiscountAmount,
        categoryDiscountAmount: categoryDiscountAmount,
        netTotal: afterCategory,
      );
    }

    var orderDiscountTotal = 0.0;
    var total = subtotal - lineDiscountTotal;

    for (final discount in discounts.where(
      (d) => d.scope == DiscountScope.wholeOrder,
    )) {
      final result = _applyDiscount(
        amount: total,
        type: discount.type,
        value: discount.value,
        label: 'Order discount',
        warnings: warnings,
      );
      orderDiscountTotal += result.reduction;
      total = result.amount;
    }

    return CartPricingBreakdown(
      subtotal: subtotal,
      lineDiscountTotal: lineDiscountTotal,
      orderDiscountTotal: orderDiscountTotal,
      total: total,
      linePricing: linePricing,
      warnings: warnings,
    );
  }

  static _DiscountResult _applyDiscount({
    required double amount,
    required DiscountType type,
    required double value,
    required String label,
    required List<String> warnings,
  }) {
    if (amount <= 0 || value <= 0) {
      return _DiscountResult(amount: amount, reduction: 0);
    }

    final rawReduction = switch (type) {
      DiscountType.percentage => amount * (value / 100),
      DiscountType.fixed => value,
    };

    final reduction = rawReduction.clamp(0, amount).toDouble();
    final nextAmount = amount - reduction;

    if (rawReduction > amount) {
      warnings.add(
        '$label clamped — entered value would exceed the available amount',
      );
    }

    return _DiscountResult(amount: nextAmount, reduction: reduction);
  }
}

class _DiscountResult {
  const _DiscountResult({required this.amount, required this.reduction});

  final double amount;
  final double reduction;
}
