import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/catalog_image.dart';
import '../../categories/providers/category_providers.dart';
import '../../deals/providers/deal_providers.dart';
import '../../settings/providers/currency_providers.dart';
import '../../tables/providers/table_providers.dart';
import '../providers/pos_catalog_providers.dart';
import '../services/pos_add_flow.dart';
import 'pos_cart_panel.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    ref.watch(dealListProvider);
    ref.watch(hallListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: categoriesAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading menu...'),
        error: (error, _) => AppEmptyState(
          title: 'Failed to load menu',
          message: error.toString(),
        ),
        data: (_) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(flex: 3, child: _PosMenuPanel()),
            SizedBox(width: spacing.lg),
            const Expanded(flex: 2, child: PosCartPanel()),
          ],
        ),
      ),
    );
  }
}

class _PosMenuPanel extends ConsumerWidget {
  const _PosMenuPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final tabs = ref.watch(posCategoryTabsProvider);
    final selectedTab = ref.watch(posSelectedTabProvider);
    final gridItems = ref.watch(posGridItemsProvider);
    final formatMoney = ref.watch(formatMoneyProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
            child: Text(
              'New order',
              style: typography.titleMedium.copyWith(color: colors.onSurface),
            ),
          ),
          SizedBox(height: spacing.sm),
          SizedBox(
            height: spacing.xxl,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              children: [
                ...tabs.map((category) {
                  final selected = selectedTab == category.id;
                  return Padding(
                    padding: EdgeInsets.only(right: spacing.sm),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: selected,
                      onSelected: (_) => ref
                          .read(posSelectedTabProvider.notifier)
                          .state = category.id,
                    ),
                  );
                }),
                ChoiceChip(
                  label: const Text('Deals'),
                  selected: selectedTab == posDealsTabId,
                  onSelected: (_) => ref
                      .read(posSelectedTabProvider.notifier)
                      .state = posDealsTabId,
                ),
              ],
            ),
          ),
          Divider(height: spacing.md, color: colors.divider),
          Expanded(
            child: gridItems.isEmpty
                ? AppEmptyState(
                    title: selectedTab == posDealsTabId
                        ? 'No deals available'
                        : 'No products in this category',
                    message: selectedTab == posDealsTabId
                        ? 'Create deals or check availability windows.'
                        : 'Add available products to this category.',
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(spacing.md),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: spacing.xxl * 3,
                      mainAxisSpacing: spacing.md,
                      crossAxisSpacing: spacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: gridItems.length,
                    itemBuilder: (context, index) {
                      final item = gridItems[index];
                      return _PosMenuTile(
                        item: item,
                        formatMoney: formatMoney,
                        onTap: () => _onItemTap(context, ref, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onItemTap(
    BuildContext context,
    WidgetRef ref,
    PosGridItem item,
  ) async {
    switch (item) {
      case PosProductItem(:final product):
        await addProductToCart(context, ref, product);
      case PosDealItem(:final deal):
        addDealToCart(ref, deal);
    }
  }
}

class _PosMenuTile extends StatelessWidget {
  const _PosMenuTile({
    required this.item,
    required this.formatMoney,
    required this.onTap,
  });

  final PosGridItem item;
  final String Function(double amount) formatMoney;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Material(
      color: colors.surfaceVariant,
      borderRadius: context.appRadius.mdBorder,
      child: InkWell(
        borderRadius: context.appRadius.mdBorder,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(spacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PosMenuImage(
                  imageUrl: item.imageUrl,
                  isDeal: item is PosDealItem,
                ),
              ),
              SizedBox(height: spacing.sm),
              Text(
                item.name,
                style: typography.bodyMedium.copyWith(color: colors.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                formatMoney(item.displayPrice),
                style: typography.labelLarge.copyWith(color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosMenuImage extends StatelessWidget {
  const _PosMenuImage({this.imageUrl, required this.isDeal});

  final String? imageUrl;
  final bool isDeal;

  @override
  Widget build(BuildContext context) {
    return CatalogImage(
      url: imageUrl,
      width: double.infinity,
      height: double.infinity,
      borderRadius: context.appRadius.smBorder,
      placeholderIcon:
          isDeal ? Icons.local_offer_outlined : Icons.fastfood_outlined,
    );
  }
}
