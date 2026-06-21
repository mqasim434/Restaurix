import 'package:restaurix/domain/models/cart_item.dart';
import 'package:restaurix/domain/models/discount.dart';
import 'package:restaurix/features/pos/services/discount_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscountCalculator', () {
    test('stacks item, category, and whole-order discounts in order', () {
      // Line A: 1000 x 1 (category beverages)
      // Line B: 500 x 2 = 1000 (category food)
      // Item discount on A: 20% => 800
      // Category discount on beverages: 10% => 720
      // Category discount on food: not applied to A
      // Subtotal after line discounts: 720 + 1000 = 1720
      // Whole order fixed 500 => 1220

      final items = [
        CartItem(
          lineId: 'line-a',
          productId: 'p1',
          categoryId: 'cat-bev',
          name: 'Coffee',
          unitPrice: 1000,
        ),
        CartItem(
          lineId: 'line-b',
          productId: 'p2',
          categoryId: 'cat-food',
          name: 'Burger',
          unitPrice: 500,
          quantity: 2,
        ),
      ];

      final discounts = [
        AppliedDiscount(
          scope: DiscountScope.item,
          targetId: 'p1',
          lineId: 'line-a',
          type: DiscountType.percentage,
          value: 20,
        ),
        AppliedDiscount(
          scope: DiscountScope.category,
          targetId: 'cat-bev',
          type: DiscountType.percentage,
          value: 10,
        ),
        AppliedDiscount(
          scope: DiscountScope.wholeOrder,
          type: DiscountType.fixed,
          value: 500,
        ),
      ];

      final result = DiscountCalculator.compute(
        items: items,
        discounts: discounts,
      );

      expect(result.subtotal, 2000);
      expect(result.linePricing['line-a']!.grossTotal, 1000);
      expect(result.linePricing['line-a']!.itemDiscountAmount, 200);
      expect(result.linePricing['line-a']!.categoryDiscountAmount, 80);
      expect(result.linePricing['line-a']!.netTotal, 720);
      expect(result.linePricing['line-b']!.netTotal, 1000);
      expect(result.subtotalAfterLineDiscounts, 1720);
      expect(result.orderDiscountTotal, 500);
      expect(result.total, 1220);
      expect(result.warnings, isEmpty);
    });

    test('clamps discounts that would push totals below zero', () {
      final items = [
        CartItem(
          lineId: 'line-a',
          productId: 'p1',
          categoryId: 'cat-bev',
          name: 'Tea',
          unitPrice: 100,
        ),
      ];

      final discounts = [
        AppliedDiscount(
          scope: DiscountScope.item,
          targetId: 'p1',
          lineId: 'line-a',
          type: DiscountType.fixed,
          value: 150,
        ),
        AppliedDiscount(
          scope: DiscountScope.wholeOrder,
          type: DiscountType.fixed,
          value: 50,
        ),
      ];

      final result = DiscountCalculator.compute(
        items: items,
        discounts: discounts,
      );

      expect(result.linePricing['line-a']!.netTotal, 0);
      expect(result.total, 0);
      expect(result.warnings, isNotEmpty);
    });

    test('applies item discount before category discount on the same line', () {
      final items = [
        CartItem(
          lineId: 'line-a',
          productId: 'p1',
          categoryId: 'cat-bev',
          name: 'Latte',
          unitPrice: 1000,
        ),
      ];

      final discounts = [
        AppliedDiscount(
          scope: DiscountScope.item,
          targetId: 'p1',
          lineId: 'line-a',
          type: DiscountType.percentage,
          value: 10,
        ),
        AppliedDiscount(
          scope: DiscountScope.category,
          targetId: 'cat-bev',
          type: DiscountType.percentage,
          value: 10,
        ),
      ];

      final result = DiscountCalculator.compute(
        items: items,
        discounts: discounts,
      );

      // 1000 - 10% = 900, then 900 - 10% = 810
      expect(result.linePricing['line-a']!.itemDiscountAmount, 100);
      expect(result.linePricing['line-a']!.categoryDiscountAmount, 90);
      expect(result.linePricing['line-a']!.netTotal, 810);
      expect(result.total, 810);
    });
  });
}
