import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/deal_item.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/product_variant.dart';
import '../../products/providers/variant_providers.dart';

class DealItemFormResult {
  const DealItemFormResult({
    required this.productId,
    this.variantId,
    required this.quantity,
  });

  final String productId;
  final String? variantId;
  final int quantity;
}

class DealItemFormDialog extends ConsumerStatefulWidget {
  const DealItemFormDialog({
    super.key,
    required this.products,
    this.item,
    this.title = 'Add Bundle Item',
  });

  final List<Product> products;
  final DealItem? item;
  final String title;

  static Future<DealItemFormResult?> show(
    BuildContext context, {
    required List<Product> products,
    DealItem? item,
    String title = 'Add Bundle Item',
  }) {
    return showDialog<DealItemFormResult>(
      context: context,
      builder: (context) => DealItemFormDialog(
        products: products,
        item: item,
        title: title,
      ),
    );
  }

  @override
  ConsumerState<DealItemFormDialog> createState() => _DealItemFormDialogState();
}

class _DealItemFormDialogState extends ConsumerState<DealItemFormDialog> {
  String? _productId;
  String? _variantId;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _productId = widget.item?.productId ??
        (widget.products.isNotEmpty ? widget.products.first.id : null);
    _variantId = widget.item?.variantId;
    _quantityController = TextEditingController(
      text: (widget.item?.quantity ?? 1).toString(),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    if (widget.products.isEmpty) {
      return AlertDialog(
        title: Text(
          widget.title,
          style: typography.titleLarge.copyWith(color: colors.onSurface),
        ),
        content: Text(
          'Create products first before adding them to a deal.',
          style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
        actions: [
          AppButton(
            label: 'Close',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    final availableProducts =
        widget.products.where((p) => p.isAvailable).toList();
    final productOptions =
        availableProducts.isNotEmpty ? availableProducts : widget.products;

    if (_productId != null &&
        !productOptions.any((p) => p.id == _productId)) {
      _productId = productOptions.first.id;
      _variantId = null;
    }

    final variantsAsync = _productId == null
        ? const AsyncValue<List<ProductVariant>>.data([])
        : ref.watch(productVariantsProvider(_productId!));

    return AlertDialog(
      title: Text(
        widget.title,
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: spacing.xxl * 6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<String>(
                label: 'Product',
                value: _productId,
                items: productOptions.map((p) => p.id).toList(),
                itemLabel: (id) {
                  final product = productOptions.firstWhere((p) => p.id == id);
                  final suffix = product.isAvailable ? '' : ' (unavailable)';
                  return '${product.name}$suffix';
                },
                onChanged: (value) => setState(() {
                  _productId = value;
                  _variantId = null;
                }),
              ),
              SizedBox(height: spacing.md),
              variantsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (variants) {
                  if (variants.isEmpty) return const SizedBox.shrink();

                  final variantIds = variants.map((v) => v.id).toList();
                  final selectedVariantId =
                      _variantId != null && variantIds.contains(_variantId)
                          ? _variantId
                          : null;

                  return Column(
                    children: [
                      AppDropdown<String?>(
                        label: 'Variant (optional)',
                        value: selectedVariantId,
                        items: [null, ...variantIds],
                        itemLabel: (id) {
                          if (id == null) return 'Any / base product';
                          final variant =
                              variants.firstWhere((v) => v.id == id);
                          return variant.name;
                        },
                        onChanged: (value) =>
                            setState(() => _variantId = value),
                      ),
                      SizedBox(height: spacing.md),
                    ],
                  );
                },
              ),
              AppTextField(
                controller: _quantityController,
                label: 'Quantity',
                hint: '1',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }

  void _submit() {
    if (_productId == null) return;

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 1) return;

    Navigator.of(context).pop(
      DealItemFormResult(
        productId: _productId!,
        variantId: _variantId,
        quantity: quantity,
      ),
    );
  }
}
