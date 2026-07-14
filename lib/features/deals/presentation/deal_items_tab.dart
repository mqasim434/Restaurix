import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/deal_item.dart';
import '../../../domain/models/product.dart';
import '../../products/providers/product_providers.dart';
import '../../products/providers/variant_providers.dart';
import '../providers/deal_providers.dart';
import 'deal_item_form_dialog.dart';

class DealItemsTab extends ConsumerWidget {
  const DealItemsTab({
    super.key,
    required this.dealId,
  });

  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final itemsAsync = ref.watch(dealItemsProvider(dealId));
    final products = ref.watch(productListProvider).valueOrNull ?? [];
    final actions = ref.read(dealActionsProvider);

    return itemsAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading bundle items...'),
      error: (error, _) => AppEmptyState(
        title: 'Failed to load bundle items',
        message: error.toString(),
      ),
      data: (items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    items.isEmpty
                        ? 'Add products to build the bundle'
                        : '${items.length} item${items.length == 1 ? '' : 's'} in bundle',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Add Item',
                  icon: AppIcons.add,
                  size: AppButtonSize.small,
                  onPressed: products.isEmpty
                      ? null
                      : () => _addItem(context, actions, products),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            Expanded(
              child: items.isEmpty
                  ? AppEmptyState(
                      title: 'No bundle items',
                      message:
                          'Pick products and quantities — bundle price is set separately.',
                      actionLabel: products.isEmpty ? null : 'Add Item',
                      onAction: products.isEmpty
                          ? null
                          : () => _addItem(context, actions, products),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colors.divider),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _DealItemRow(
                          item: item,
                          products: products,
                          onEdit: () =>
                              _editItem(context, actions, products, item),
                          onDelete: () => _deleteItem(context, actions, item),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addItem(
    BuildContext context,
    DealActions actions,
    List<Product> products,
  ) async {
    final result = await DealItemFormDialog.show(context, products: products);
    if (result == null || !context.mounted) return;

    await actions.createItem(
      dealId: dealId,
      productId: result.productId,
      variantId: result.variantId,
      quantity: result.quantity,
    );
  }

  Future<void> _editItem(
    BuildContext context,
    DealActions actions,
    List<Product> products,
    DealItem item,
  ) async {
    final result = await DealItemFormDialog.show(
      context,
      products: products,
      item: item,
      title: 'Edit Bundle Item',
    );
    if (result == null || !context.mounted) return;

    await actions.updateItem(
      item.copyWith(
        productId: result.productId,
        variantId: result.variantId,
        clearVariantId: result.variantId == null,
        quantity: result.quantity,
      ),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    DealActions actions,
    DealItem item,
  ) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Remove bundle item?',
      content: Text(
        'Remove this item from the deal bundle?',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Remove',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await actions.deleteItem(item.id);
    if (!deleted && context.mounted) {
      AppSnackbar.error(context, 'Could not remove bundle item');
    }
  }
}

class _DealItemRow extends ConsumerWidget {
  const _DealItemRow({
    required this.item,
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  final DealItem item;
  final List<Product> products;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    final product = products.where((p) => p.id == item.productId).firstOrNull;
    final variantsAsync = ref.watch(productVariantsProvider(item.productId));

    final variantName = variantsAsync.valueOrNull
        ?.where((v) => v.id == item.variantId)
        .map((v) => v.name)
        .firstOrNull;

    final productLabel = product?.name ?? 'Unknown product';
    final unavailable = product != null && !product.isAvailable;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity}x $productLabel',
                  style: typography.bodyMedium.copyWith(
                    color: unavailable ? colors.error : colors.onSurface,
                  ),
                ),
                Text(
                  [
                    if (variantName != null) variantName,
                    if (unavailable) 'Product unavailable',
                  ].join(' · '),
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: Icon(AppIcons.edit, color: colors.onSurfaceVariant),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(AppIcons.delete, color: colors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
