import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/discount.dart';
import '../services/discount_calculator.dart';
import 'cart_providers.dart';

final cartDiscountsProvider =
    NotifierProvider<CartDiscountNotifier, List<AppliedDiscount>>(
  CartDiscountNotifier.new,
);

final cartPricingProvider = Provider<CartPricingBreakdown>((ref) {
  final items = ref.watch(cartProvider);
  final discounts = ref.watch(cartDiscountsProvider);
  return DiscountCalculator.compute(items: items, discounts: discounts);
});

class CartDiscountNotifier extends Notifier<List<AppliedDiscount>> {
  @override
  List<AppliedDiscount> build() => const [];

  void upsertItemDiscount(AppliedDiscount discount) {
    final others = state
        .where(
          (existing) =>
              !(existing.scope == DiscountScope.item &&
                  existing.lineId == discount.lineId),
        )
        .toList();
    state = [...others, discount];
  }

  void upsertCategoryDiscount(AppliedDiscount discount) {
    final others = state
        .where(
          (existing) =>
              !(existing.scope == DiscountScope.category &&
                  existing.targetId == discount.targetId),
        )
        .toList();
    state = [...others, discount];
  }

  void upsertWholeOrderDiscount(AppliedDiscount discount) {
    final others =
        state.where((existing) => existing.scope != DiscountScope.wholeOrder);
    state = [...others, discount];
  }

  void remove(String discountId) {
    state = state.where((discount) => discount.id != discountId).toList();
  }

  void clear() {
    state = const [];
  }

  void replaceAll(List<AppliedDiscount> discounts) {
    state = discounts;
  }
}
