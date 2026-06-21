import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/discount.dart';
import '../../categories/providers/category_providers.dart';
import '../providers/discount_providers.dart';
import 'discount_form_dialog.dart';

Future<void> showCategoryDiscountPicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final categories = ref.read(categoryListProvider).valueOrNull ?? [];
  if (categories.isEmpty) {
    AppSnackbar.info(context, 'Add categories before applying category discounts');
    return;
  }

  final category = await showDialog<Category>(
    context: context,
    builder: (context) => _CategoryPickerDialog(categories: categories),
  );

  if (category == null || !context.mounted) return;

  final existing = ref.read(cartDiscountsProvider).where(
        (discount) =>
            discount.scope == DiscountScope.category &&
            discount.targetId == category.id,
      );

  final config = await DiscountFormDialog.show(
    context: context,
    title: 'Category discount',
    subtitle: category.name,
    initialType: existing.isNotEmpty ? existing.first.type : DiscountType.percentage,
    initialValue: existing.isNotEmpty ? existing.first.value : null,
    initialReason: existing.isNotEmpty ? existing.first.reason : null,
  );

  if (config == null) return;

  ref.read(cartDiscountsProvider.notifier).upsertCategoryDiscount(
        AppliedDiscount(
          scope: DiscountScope.category,
          targetId: category.id,
          type: config.type,
          value: config.value,
          reason: config.reason,
        ),
      );

  if (context.mounted) {
    final pricing = ref.read(cartPricingProvider);
    for (final warning in pricing.warnings) {
      AppSnackbar.info(context, warning);
    }
  }
}

Future<void> showWholeOrderDiscountDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final existing = ref.read(cartDiscountsProvider).where(
        (discount) => discount.scope == DiscountScope.wholeOrder,
      );

  final config = await DiscountFormDialog.show(
    context: context,
    title: 'Whole-order discount',
    subtitle: 'Applied after item and category discounts',
    initialType: existing.isNotEmpty ? existing.first.type : DiscountType.percentage,
    initialValue: existing.isNotEmpty ? existing.first.value : null,
    initialReason: existing.isNotEmpty ? existing.first.reason : null,
  );

  if (config == null) return;

  ref.read(cartDiscountsProvider.notifier).upsertWholeOrderDiscount(
        AppliedDiscount(
          scope: DiscountScope.wholeOrder,
          type: config.type,
          value: config.value,
          reason: config.reason,
        ),
      );

  if (context.mounted) {
    final pricing = ref.read(cartPricingProvider);
    for (final warning in pricing.warnings) {
      AppSnackbar.info(context, warning);
    }
  }
}

Future<void> showItemDiscountDialog(
  BuildContext context,
  WidgetRef ref, {
  required String lineId,
  required String name,
  String? targetId,
}) async {
  final existing = ref.read(cartDiscountsProvider).where(
        (discount) =>
            discount.scope == DiscountScope.item && discount.lineId == lineId,
      );

  final config = await DiscountFormDialog.show(
    context: context,
    title: 'Item discount',
    subtitle: name,
    initialType: existing.isNotEmpty ? existing.first.type : DiscountType.percentage,
    initialValue: existing.isNotEmpty ? existing.first.value : null,
    initialReason: existing.isNotEmpty ? existing.first.reason : null,
  );

  if (config == null) return;

  ref.read(cartDiscountsProvider.notifier).upsertItemDiscount(
        AppliedDiscount(
          scope: DiscountScope.item,
          targetId: targetId,
          lineId: lineId,
          type: config.type,
          value: config.value,
          reason: config.reason,
        ),
      );

  if (context.mounted) {
    final pricing = ref.read(cartPricingProvider);
    for (final warning in pricing.warnings) {
      AppSnackbar.info(context, warning);
    }
  }
}

class _CategoryPickerDialog extends StatelessWidget {
  const _CategoryPickerDialog({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return AppDialog(
      title: 'Discount by category',
      showActions: false,
      content: SizedBox(
        width: 360,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: categories.length,
          separatorBuilder: (_, __) => SizedBox(height: spacing.xs),
          itemBuilder: (context, index) {
            final category = categories[index];
            return AppButton(
              label: category.name,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(context).pop(category),
            );
          },
        ),
      ),
    );
  }
}
