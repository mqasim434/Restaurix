import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/models/product_variant.dart';
import '../../products/presentation/product_form_dialog.dart';

class VariantPickerSheet extends StatelessWidget {
  const VariantPickerSheet({
    super.key,
    required this.productName,
    required this.variants,
    required this.basePrice,
  });

  final String productName;
  final List<ProductVariant> variants;
  final double basePrice;

  static Future<ProductVariant?> show(
    BuildContext context, {
    required String productName,
    required List<ProductVariant> variants,
    required double basePrice,
  }) {
    return showModalBottomSheet<ProductVariant>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => VariantPickerSheet(
        productName: productName,
        variants: variants,
        basePrice: basePrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose variant',
            style: typography.titleMedium.copyWith(color: colors.onSurface),
          ),
          Text(
            productName,
            style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: spacing.md),
          ...variants.map((variant) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Material(
                color: colors.surfaceVariant,
                borderRadius: context.appRadius.mdBorder,
                child: InkWell(
                  borderRadius: context.appRadius.mdBorder,
                  onTap: () => Navigator.of(context).pop(variant),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            variant.name,
                            style: typography.bodyMedium.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          formatProductPrice(variant.price),
                          style: typography.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
