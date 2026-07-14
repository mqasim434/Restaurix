import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_format.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/product_variant.dart';
import '../../settings/providers/currency_providers.dart';
import '../providers/variant_providers.dart';
import 'variant_form_dialog.dart';

class ProductVariantsTab extends ConsumerStatefulWidget {
  const ProductVariantsTab({
    super.key,
    required this.productId,
    required this.basePrice,
  });

  final String productId;
  final double Function() basePrice;

  @override
  ConsumerState<ProductVariantsTab> createState() => _ProductVariantsTabState();
}

class _ProductVariantsTabState extends ConsumerState<ProductVariantsTab> {
  List<ProductVariant>? _localOrder;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final variantsAsync = ref.watch(productVariantsProvider(widget.productId));
    final actions = ref.read(variantActionsProvider);

    return variantsAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading variants...'),
      error: (error, _) => AppEmptyState(
        title: 'Failed to load variants',
        message: error.toString(),
      ),
      data: (variants) {
        final displayVariants = _localOrder ?? variants;
        final defaultVariantId = displayVariants
            .where((v) => v.isDefault)
            .map((v) => v.id)
            .firstOrNull;

        final formatMoney = ref.watch(formatMoneyProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CustomerPreview(
              basePrice: widget.basePrice(),
              variants: displayVariants,
              formatMoney: formatMoney,
            ),
            SizedBox(height: spacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    variants.isEmpty
                        ? 'No variants — product sells at base price'
                        : '${variants.length} variant${variants.length == 1 ? '' : 's'}',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Add Variant',
                  icon: AppIcons.add,
                  size: AppButtonSize.small,
                  onPressed: () => _addVariant(context, actions),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            Expanded(
              child: displayVariants.isEmpty
                  ? AppEmptyState(
                      title: 'No variants',
                      message:
                          'Leave empty to sell at base price, or add sizes/options.',
                      actionLabel: 'Add Variant',
                      onAction: () => _addVariant(context, actions),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: displayVariants.length,
                      onReorder: (oldIndex, newIndex) async {
                        setState(() {
                          final items = List<ProductVariant>.of(displayVariants);
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = items.removeAt(oldIndex);
                          items.insert(newIndex, item);
                          _localOrder = items;
                        });
                        await actions.reorder(
                          productId: widget.productId,
                          idsInOrder: _localOrder!.map((v) => v.id).toList(),
                        );
                        if (mounted) setState(() => _localOrder = null);
                      },
                      itemBuilder: (context, index) {
                        final variant = displayVariants[index];
                        return _VariantRow(
                          key: ValueKey(variant.id),
                          variant: variant,
                          index: index,
                          defaultVariantId: defaultVariantId,
                          formatMoney: formatMoney,
                          onEdit: () => _editVariant(context, actions, variant),
                          onDelete: () =>
                              _deleteVariant(context, actions, variant),
                          onSetDefault: () => actions.setDefault(
                            variantId: variant.id,
                            productId: widget.productId,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addVariant(BuildContext context, VariantActions actions) async {
    final result = await VariantFormDialog.show(context);
    if (result == null || !context.mounted) return;

    await actions.create(
      productId: widget.productId,
      name: result.name,
      price: result.price,
      isDefault: result.isDefault,
    );
  }

  Future<void> _editVariant(
    BuildContext context,
    VariantActions actions,
    ProductVariant variant,
  ) async {
    final result = await VariantFormDialog.show(
      context,
      title: 'Edit Variant',
      initialName: variant.name,
      initialPrice: variant.price,
      initialIsDefault: variant.isDefault,
    );
    if (result == null || !context.mounted) return;

    await actions.update(
      variant.copyWith(
        name: result.name,
        price: result.price,
        isDefault: result.isDefault,
      ),
    );
  }

  Future<void> _deleteVariant(
    BuildContext context,
    VariantActions actions,
    ProductVariant variant,
  ) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Remove variant?',
      content: Text(
        'Remove "${variant.name}"? Past orders keep their price snapshot.',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Remove',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await actions.delete(variant.id);
    if (!deleted && context.mounted) {
      AppSnackbar.error(context, 'Could not remove variant');
    }
  }
}

class _CustomerPreview extends StatelessWidget {
  const _CustomerPreview({
    required this.basePrice,
    required this.variants,
    required this.formatMoney,
  });

  final double basePrice;
  final List<ProductVariant> variants;
  final MoneyFormatter formatMoney;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer preview',
            style: typography.labelLarge.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: spacing.sm),
          if (variants.isEmpty)
            Text(
              'One tap add — ${formatMoney(basePrice)}',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else if (variants.length == 1)
            Text(
              'Auto-selected at POS — ${variants.first.name} '
              '(${formatMoney(variants.first.price)})',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: variants.map((variant) {
              return ChoiceChip(
                label: Text(
                  '${variant.name} · ${formatMoney(variant.price)}',
                  style: typography.labelMedium.copyWith(
                    color: variant.isDefault
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
                selected: variant.isDefault,
                onSelected: (_) {},
                selectedColor: colors.primaryContainer,
                backgroundColor: colors.surface,
                side: BorderSide(
                  color: variant.isDefault ? colors.primary : colors.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    super.key,
    required this.variant,
    required this.index,
    required this.defaultVariantId,
    required this.formatMoney,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final ProductVariant variant;
  final int index;
  final String? defaultVariantId;
  final MoneyFormatter formatMoney;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Material(
      key: key,
      color: colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.xs),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded, color: colors.onSurfaceVariant),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.name,
                    style: typography.bodyMedium.copyWith(color: colors.onSurface),
                  ),
                  Text(
                    formatMoney(variant.price),
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: variant.id,
              groupValue: defaultVariantId,
              onChanged: (_) => onSetDefault(),
            ),
            Text(
              'Default',
              style: typography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
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
      ),
    );
  }
}
