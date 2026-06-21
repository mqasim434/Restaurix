import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/category.dart';
import '../../../domain/models/deal.dart';
import '../../../domain/models/product.dart';
import '../../categories/providers/category_providers.dart';
import '../../deals/providers/deal_providers.dart';
import '../../products/providers/product_providers.dart';

/// POS category tab id, or [posDealsTabId] for the deals tab.
final posSelectedTabProvider = StateProvider<String>((ref) {
  final categories = ref.watch(posCategoryTabsProvider);
  if (categories.isEmpty) return posDealsTabId;
  return categories.first.id;
});

const posDealsTabId = '__deals__';

final posCategoryTabsProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoryListProvider).valueOrNull ?? [];
  return categories.where((category) => category.isActive).toList();
});

final posAvailableProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productListProvider).valueOrNull ?? [];
  return products.where((product) => product.isAvailable).toList();
});

final posProductsForTabProvider = Provider<List<Product>>((ref) {
  final tabId = ref.watch(posSelectedTabProvider);
  if (tabId == posDealsTabId) return const [];

  return ref
      .watch(posAvailableProductsProvider)
      .where((product) => product.categoryId == tabId)
      .toList();
});

final posAvailableDealsProvider = Provider<List<Deal>>((ref) {
  final deals = ref.watch(dealListProvider).valueOrNull ?? [];
  final products = ref.watch(productListProvider).valueOrNull ?? [];
  final productsById = productMapById(products);

  return deals.where((deal) {
    final items = ref.watch(dealItemsProvider(deal.id)).valueOrNull ?? [];
    return deal.isEffectivelyAvailable(
      items: items,
      productsById: productsById,
    );
  }).toList();
});

/// Grid items for the currently selected POS tab.
final posGridItemsProvider = Provider<List<PosGridItem>>((ref) {
  final tabId = ref.watch(posSelectedTabProvider);

  if (tabId == posDealsTabId) {
    return ref
        .watch(posAvailableDealsProvider)
        .map(PosGridItem.deal)
        .toList();
  }

  return ref
      .watch(posProductsForTabProvider)
      .map(PosGridItem.product)
      .toList();
});

sealed class PosGridItem {
  const PosGridItem();

  factory PosGridItem.product(Product product) = PosProductItem;
  factory PosGridItem.deal(Deal deal) = PosDealItem;

  String get id;
  String get name;
  double get displayPrice;
  String? get imageUrl;
}

class PosProductItem extends PosGridItem {
  PosProductItem(this.product);

  final Product product;

  @override
  String get id => product.id;

  @override
  String get name => product.name;

  @override
  double get displayPrice => product.basePrice;

  @override
  String? get imageUrl => product.imageUrl;
}

class PosDealItem extends PosGridItem {
  PosDealItem(this.deal);

  final Deal deal;

  @override
  String get id => deal.id;

  @override
  String get name => deal.name;

  @override
  double get displayPrice => deal.price;

  @override
  String? get imageUrl => deal.imageUrl;
}
