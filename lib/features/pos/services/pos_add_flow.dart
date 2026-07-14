import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/cart_item.dart';
import '../../../domain/models/deal.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/product_variant.dart';
import '../../products/providers/variant_providers.dart';
import '../presentation/variant_picker_sheet.dart';
import '../providers/cart_providers.dart';

/// Orchestrates variant picker and adds lines to the cart.
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

  final unitPrice = computeCartUnitPrice(
    basePrice: product.basePrice,
    variantPrice: selectedVariant?.price,
  );

  ref.read(cartProvider.notifier).add(
        CartItem(
          productId: product.id,
          categoryId: product.categoryId,
          name: product.name,
          unitPrice: unitPrice,
          variantId: selectedVariant?.id,
          variantName: selectedVariant?.name,
          variantPriceOverride: selectedVariant?.price,
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
