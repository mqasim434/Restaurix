import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/models/product_variant.dart';
import '../../settings/providers/currency_providers.dart';

class VariantPickerSheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final formatMoney = ref.watch(formatMoneyProvider);

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
                          formatMoney(variant.price),
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
