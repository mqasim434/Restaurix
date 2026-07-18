import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/prepare_catalog_image.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/catalog_image.dart';
import '../../../data/remote/imagekit_upload_service.dart';
import '../../../domain/models/deal.dart';
import '../../../domain/models/product.dart';
import '../../categories/providers/category_providers.dart';
import '../../products/providers/product_providers.dart';
import '../../settings/providers/currency_providers.dart';
import '../providers/deal_providers.dart';
import 'deal_form_dialog.dart';

class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final dealsAsync = ref.watch(dealListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    final categoryNames = <String, String>{
      for (final c in categoriesAsync.valueOrNull ?? []) c.id: c.name,
    };

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Build bundled deals with a flat price for POS',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppButton(
                label: 'Add Deal',
                icon: AppIcons.add,
                onPressed: () => _openForm(context, ref),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: dealsAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading deals...'),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load deals',
                message: error.toString(),
              ),
              data: (deals) {
                if (deals.isEmpty) {
                  return AppEmptyState(
                    title: 'No deals yet',
                    message:
                        'Create combo bundles that appear in POS like products.',
                    actionLabel: 'Add Deal',
                    onAction: () => _openForm(context, ref),
                  );
                }

                return _DealTable(
                  deals: deals,
                  categoryNames: categoryNames,
                  onEdit: (deal) => _openForm(context, ref, deal: deal),
                  onDelete: (deal) => _confirmDelete(context, ref, deal),
                  onToggleAvailability: (deal) =>
                      _toggleAvailability(context, ref, deal),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Deal? deal,
  }) async {
    final categories = ref.read(categoryListProvider).valueOrNull ?? [];

    final result = await DealFormDialog.show(
      context,
      categories: categories,
      deal: deal,
    );
    if (result == null || !context.mounted) return;

    late final String? imageUrl;
    try {
      imageUrl = await prepareCatalogImageUrl(
        context: context,
        imageUrl: result.imageUrl,
        clearImage: result.clearImage,
        folder: ImageKitFolders.deals,
      );
    } on ImageKitException {
      return;
    }
    if (!context.mounted) return;

    final notifier = ref.read(dealListProvider.notifier);
    final DealMutationResult mutation;

    if (deal == null) {
      mutation = await notifier.create(
        name: result.name,
        price: result.price,
        description: result.description,
        imageUrl: imageUrl,
        categoryId: result.categoryId,
        isAvailable: result.isAvailable,
        availabilityStart: result.availabilityStart,
        availabilityEnd: result.availabilityEnd,
      );
    } else {
      mutation = await notifier.updateDeal(
        deal.copyWith(
          name: result.name,
          price: result.price,
          description: result.description,
          clearDescription: result.clearDescription,
          imageUrl: imageUrl,
          clearImageUrl: result.clearImage,
          categoryId: result.categoryId,
          clearCategoryId: result.clearCategoryId,
          isAvailable: result.isAvailable,
          availabilityStart: result.availabilityStart,
          availabilityEnd: result.availabilityEnd,
          clearAvailabilityStart: result.clearAvailabilityStart,
          clearAvailabilityEnd: result.clearAvailabilityEnd,
        ),
      );
    }

    if (!context.mounted) return;
    if (!mutation.success && mutation.errorMessage != null) {
      AppSnackbar.error(context, mutation.errorMessage!);
    }
  }

  Future<void> _toggleAvailability(
    BuildContext context,
    WidgetRef ref,
    Deal deal,
  ) async {
    final mutation =
        await ref.read(dealListProvider.notifier).toggleAvailability(deal.id);
    if (!context.mounted) return;
    if (!mutation.success && mutation.errorMessage != null) {
      AppSnackbar.error(context, mutation.errorMessage!);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Deal deal,
  ) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete deal?',
      content: Text(
        'Delete "${deal.name}"? This removes the deal from active menus.',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final mutation =
        await ref.read(dealListProvider.notifier).delete(deal.id);
    if (!context.mounted) return;
    if (!mutation.success && mutation.errorMessage != null) {
      AppSnackbar.error(context, mutation.errorMessage!);
    }
  }
}

class _DealTable extends ConsumerWidget {
  const _DealTable({
    required this.deals,
    required this.categoryNames,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  final List<Deal> deals;
  final Map<String, String> categoryNames;
  final void Function(Deal deal) onEdit;
  final void Function(Deal deal) onDelete;
  final void Function(Deal deal) onToggleAvailability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final products = ref.watch(productListProvider).valueOrNull ?? [];
    final productsById = productMapById(products);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.appRadius.md),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: spacing.xl + spacing.sm),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Name',
                    style: typography.labelLarge.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Category',
                    style: typography.labelLarge.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Price',
                    style: typography.labelLarge.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Effective',
                    style: typography.labelLarge.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Manual',
                    style: typography.labelLarge.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: spacing.xxl * 2,
                  child: Text(
                    'Actions',
                    style: typography.labelLarge.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: ListView.separated(
              itemCount: deals.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colors.divider, indent: spacing.md),
              itemBuilder: (context, index) {
                final deal = deals[index];
                return _DealRow(
                  deal: deal,
                  categoryNames: categoryNames,
                  productsById: productsById,
                  onEdit: () => onEdit(deal),
                  onDelete: () => onDelete(deal),
                  onToggleAvailability: () => onToggleAvailability(deal),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DealRow extends ConsumerWidget {
  const _DealRow({
    required this.deal,
    required this.categoryNames,
    required this.productsById,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  final Deal deal;
  final Map<String, String> categoryNames;
  final Map<String, Product> productsById;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final items = ref.watch(dealItemsProvider(deal.id)).valueOrNull ?? [];
    final formatMoney = ref.watch(formatMoneyProvider);

    final effective = deal.isEffectivelyAvailable(
      items: items,
      productsById: productsById,
    );

    String effectiveLabel;
    Color effectiveColor;
    if (effective) {
      effectiveLabel = 'Available';
      effectiveColor = colors.success;
    } else if (!deal.isAvailable) {
      effectiveLabel = 'Disabled';
      effectiveColor = colors.onSurfaceVariant;
    } else if (!deal.isWithinAvailabilityWindow()) {
      effectiveLabel = 'Outside window';
      effectiveColor = colors.warning;
    } else if (items.isEmpty) {
      effectiveLabel = 'No items';
      effectiveColor = colors.warning;
    } else {
      effectiveLabel = 'Unavailable items';
      effectiveColor = colors.error;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      child: Row(
        children: [
          _DealImageThumb(imageUrl: deal.imageUrl),
          SizedBox(width: spacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              deal.name,
              style: typography.bodyMedium.copyWith(color: colors.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              deal.categoryId == null
                  ? 'Deals section'
                  : (categoryNames[deal.categoryId] ?? 'Unknown'),
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              formatMoney(deal.price),
              style: typography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              effectiveLabel,
              style: typography.bodySmall.copyWith(color: effectiveColor),
            ),
          ),
          Expanded(
            child: Switch(
              value: deal.isAvailable,
              onChanged: (_) => onToggleAvailability(),
            ),
          ),
          SizedBox(
            width: spacing.xxl * 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
        ],
      ),
    );
  }
}

class _DealImageThumb extends StatelessWidget {
  const _DealImageThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final size = context.appSpacing.xl;
    return CatalogImage(
      url: imageUrl,
      width: size,
      height: size,
      borderRadius: context.appRadius.smBorder,
      placeholderIcon: Icons.local_offer_outlined,
    );
  }
}
