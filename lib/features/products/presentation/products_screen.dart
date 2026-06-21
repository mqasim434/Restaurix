import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/product.dart';
import '../../categories/providers/category_providers.dart';
import '../providers/product_providers.dart';
import 'product_form_dialog.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(productSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final productsAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final categoryFilter = ref.watch(productCategoryFilterProvider);

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
                  'Manage menu products and availability',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppButton(
                label: 'Add Product',
                icon: AppIcons.add,
                onPressed: categoriesAsync.valueOrNull?.isNotEmpty == true
                    ? () => _openForm(context)
                    : null,
              ),
              SizedBox(width: spacing.sm),
              AppButton(
                label: 'Modifier Groups',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go('/modifier-groups'),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Search by name...',
                  prefixIcon: AppIcons.search,
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: _CategoryFilterDropdown(
                  categories: categoriesAsync.valueOrNull ?? [],
                  selectedCategoryId: categoryFilter,
                  onChanged: (value) =>
                      ref.read(productCategoryFilterProvider.notifier).state =
                          value,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading products...'),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load products',
                message: error.toString(),
              ),
              data: (products) {
                if (products.isEmpty) {
                  final hasProducts =
                      (ref.read(productListProvider).valueOrNull?.isNotEmpty ??
                          false);
                  return AppEmptyState(
                    title: hasProducts ? 'No matching products' : 'No products yet',
                    message: hasProducts
                        ? 'Try a different search or category filter.'
                        : 'Add your first product to build the menu.',
                    actionLabel:
                        hasProducts ? null : 'Add Product',
                    onAction: hasProducts
                        ? null
                        : () => _openForm(context),
                  );
                }

                return _ProductTable(
                  products: products,
                  categoryNames: categoryNames,
                  onEdit: (product) => _openForm(context, product: product),
                  onDelete: (product) => _confirmDelete(context, product),
                  onToggleAvailability: (product) =>
                      _toggleAvailability(context, product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? product}) async {
    final categories = ref.read(categoryListProvider).valueOrNull ?? [];
    if (categories.isEmpty) {
      AppSnackbar.info(context, 'Create a category before adding products.');
      return;
    }

    final result = await ProductFormDialog.show(
      context,
      categories: categories,
      product: product,
    );
    if (result == null || !context.mounted) return;

    final notifier = ref.read(productListProvider.notifier);
    final ProductMutationResult mutation;

    if (product == null) {
      mutation = await notifier.create(
        name: result.name,
        categoryId: result.categoryId,
        basePrice: result.basePrice,
        description: result.description,
        imageUrl: result.imageUrl,
        isAvailable: result.isAvailable,
        kitchenCategory: result.kitchenCategory,
        printerId: result.printerId,
      );
    } else {
      mutation = await notifier.updateProduct(
        product.copyWith(
          name: result.name,
          categoryId: result.categoryId,
          basePrice: result.basePrice,
          description: result.description,
          clearDescription: result.description == null,
          imageUrl: result.imageUrl,
          clearImageUrl: result.clearImage,
          isAvailable: result.isAvailable,
          kitchenCategory: result.kitchenCategory,
          printerId: result.printerId,
          clearPrinterId: result.clearPrinterId,
        ),
      );
    }

    if (!context.mounted) return;
    if (!mutation.success && mutation.errorMessage != null) {
      AppSnackbar.error(context, mutation.errorMessage!);
    }
  }

  Future<void> _toggleAvailability(BuildContext context, Product product) async {
    final mutation = await ref
        .read(productListProvider.notifier)
        .toggleAvailability(product.id);
    if (!context.mounted) return;
    if (!mutation.success && mutation.errorMessage != null) {
      AppSnackbar.error(context, mutation.errorMessage!);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete product?',
      content: Text(
        'Delete "${product.name}"? Historical orders keep a price snapshot '
        '— this only removes the product from active menus.',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final mutation =
        await ref.read(productListProvider.notifier).delete(product.id);
    if (!context.mounted) return;
    if (!mutation.success && mutation.errorMessage != null) {
      AppSnackbar.error(context, mutation.errorMessage!);
    }
  }
}

class _CategoryFilterDropdown extends StatelessWidget {
  const _CategoryFilterDropdown({
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: typography.labelLarge.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: spacing.xs),
        DropdownButtonFormField<String?>(
          value: selectedCategoryId,
          decoration: const InputDecoration(),
          isExpanded: true,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All categories',
                style: typography.bodyMedium.copyWith(color: colors.onSurface),
              ),
            ),
            ...categories.map(
              (category) => DropdownMenuItem<String?>(
                value: category.id,
                child: Text(
                  category.name,
                  style: typography.bodyMedium.copyWith(color: colors.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ProductTable extends StatelessWidget {
  const _ProductTable({
    required this.products,
    required this.categoryNames,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  final List<Product> products;
  final Map<String, String> categoryNames;
  final void Function(Product product) onEdit;
  final void Function(Product product) onDelete;
  final void Function(Product product) onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

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
                  child: Text(
                    'Available',
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
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colors.divider, indent: spacing.md),
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.sm,
                  ),
                  child: Row(
                    children: [
                      _ProductImageThumb(imageUrl: product.imageUrl),
                      SizedBox(width: spacing.sm),
                      Expanded(
                        flex: 3,
                        child: Text(
                          product.name,
                          style: typography.bodyMedium.copyWith(
                            color: colors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          categoryNames[product.categoryId] ?? 'Unknown',
                          style: typography.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatProductPrice(product.basePrice),
                          style: typography.bodyMedium.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Switch(
                          value: product.isAvailable,
                          onChanged: (_) => onToggleAvailability(product),
                        ),
                      ),
                      SizedBox(
                        width: spacing.xxl * 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: Icon(
                                AppIcons.edit,
                                color: colors.onSurfaceVariant,
                              ),
                              onPressed: () => onEdit(product),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: Icon(AppIcons.delete, color: colors.error),
                              onPressed: () => onDelete(product),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImageThumb extends StatelessWidget {
  const _ProductImageThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final radius = context.appRadius;
    final spacing = context.appSpacing;
    final size = spacing.xl;

    if (imageUrl != null && File(imageUrl!).existsSync()) {
      return ClipRRect(
        borderRadius: radius.smBorder,
        child: Image.file(
          File(imageUrl!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context, size),
        ),
      );
    }

    return _placeholder(context, size);
  }

  Widget _placeholder(BuildContext context, double size) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: radius.smBorder,
        border: Border.all(color: colors.border),
      ),
      child: Icon(
        Icons.image_outlined,
        size: size * 0.5,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
