import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/cart_item.dart';
import '../../../domain/models/deal.dart';
import '../../../domain/models/item_modifier.dart';
import '../../../domain/models/modifier_group.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/product_variant.dart';
import '../../modifiers/providers/modifier_providers.dart';
import '../../products/providers/variant_providers.dart';
import '../presentation/modifier_picker_sheet.dart';
import '../presentation/variant_picker_sheet.dart';
import '../providers/cart_providers.dart';
/// Orchestrates variant/modifier pickers and adds lines to the cart.
Future<void> addProductToCart(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final variantRepo = ref.read(variantRepositoryProvider);
  final variants = await variantRepo.getByProductId(product.id);

  ProductVariant? selectedVariant;
  if (variants.length > 1) {
    if (!context.mounted) return;
    selectedVariant = await VariantPickerSheet.show(
      context,
      productName: product.name,
      variants: variants,
      basePrice: product.basePrice,
    );
    if (selectedVariant == null) return;
  } else if (variants.length == 1) {
    selectedVariant = variants.first;
  }

  final groups = _resolveModifierGroups(ref, product.modifierGroupIds);
  final modifiersByGroup = await _loadModifiersByGroup(ref, groups);

  List<CartModifier> selectedModifiers = const [];
  if (groups.isNotEmpty) {
    if (!context.mounted) return;
    final picked = await ModifierPickerSheet.show(
      context,
      productName: product.name,
      groups: groups,
      modifiersByGroupId: modifiersByGroup,
    );
    if (picked == null) return;
    selectedModifiers = picked;
  }

  final unitPrice = computeCartUnitPrice(
    basePrice: product.basePrice,
    variantPrice: selectedVariant?.price,
    modifiers: selectedModifiers,
  );

  ref.read(cartProvider.notifier).add(
        CartItem(
          productId: product.id,
          name: product.name,
          unitPrice: unitPrice,
          variantId: selectedVariant?.id,
          variantName: selectedVariant?.name,
          variantPriceOverride: selectedVariant?.price,
          modifiers: selectedModifiers,
        ),
      );
}

void addDealToCart(WidgetRef ref, Deal deal) {
  ref.read(cartProvider.notifier).add(
        CartItem(
          dealId: deal.id,
          name: deal.name,
          unitPrice: deal.price,
        ),
      );
}

List<ModifierGroup> _resolveModifierGroups(
  WidgetRef ref,
  List<String> groupIds,
) {
  if (groupIds.isEmpty) return const [];

  final allGroups = ref.read(modifierGroupListProvider).valueOrNull ?? [];
  return [
    for (final id in groupIds)
      if (allGroups.any((group) => group.id == id))
        allGroups.firstWhere((group) => group.id == id),
  ];
}

Future<Map<String, List<ItemModifier>>> _loadModifiersByGroup(
  WidgetRef ref,
  List<ModifierGroup> groups,
) async {
  final repo = ref.read(modifierGroupRepositoryProvider);
  final result = <String, List<ItemModifier>>{};

  for (final group in groups) {
    result[group.id] = await repo.watchModifiersByGroup(group.id).first;
  }

  return result;
}
