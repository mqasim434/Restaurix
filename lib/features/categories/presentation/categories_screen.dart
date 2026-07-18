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
import '../../../domain/models/category.dart';
import '../providers/category_providers.dart';
import 'category_form_dialog.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final categoriesAsync = ref.watch(categoryListProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manage product categories for your menu',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppButton(
                label: 'Add Category',
                icon: AppIcons.add,
                onPressed: () => _openForm(context, ref),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: categoriesAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading categories...'),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load categories',
                message: error.toString(),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return AppEmptyState(
                    title: 'No categories yet',
                    message: 'Add your first category to organize products.',
                    actionLabel: 'Add Category',
                    onAction: () => _openForm(context, ref),
                  );
                }

                return _CategoryTable(
                  categories: categories,
                  onReorder: (ids) =>
                      ref.read(categoryListProvider.notifier).reorder(ids),
                  onEdit: (category) => _openForm(context, ref, category: category),
                  onDelete: (category) => _confirmDelete(context, ref, category),
                  onToggleActive: (category) =>
                      _toggleActive(context, ref, category),
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
    Category? category,
  }) async {
    final result = await CategoryFormDialog.show(context, category: category);
    if (result == null || !context.mounted) return;

    late final String? imageUrl;
    try {
      imageUrl = await prepareCatalogImageUrl(
        context: context,
        imageUrl: result.imageUrl,
        clearImage: result.clearImage,
        folder: ImageKitFolders.categories,
      );
    } on ImageKitException {
      return;
    }
    if (!context.mounted) return;

    final notifier = ref.read(categoryListProvider.notifier);
    final CategoryMutationResult mutation;

    if (category == null) {
      mutation = await notifier.create(
        name: result.name,
        imageUrl: imageUrl,
        isActive: result.isActive,
      );
    } else {
      mutation = await notifier.updateCategory(
        category.copyWith(
          name: result.name,
          imageUrl: imageUrl,
          clearImageUrl: result.clearImage,
          isActive: result.isActive,
        ),
      );
    }

    if (!context.mounted) return;
    _showMutationFeedback(context, mutation);
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final mutation =
        await ref.read(categoryListProvider.notifier).toggleActive(category);
    if (!context.mounted) return;
    _showMutationFeedback(context, mutation);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete category?',
      content: Text(
        'Delete "${category.name}"? This cannot be undone.',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final mutation =
        await ref.read(categoryListProvider.notifier).delete(category.id);
    if (!context.mounted) return;
    _showMutationFeedback(context, mutation);
  }

  void _showMutationFeedback(
    BuildContext context,
    CategoryMutationResult result,
  ) {
    if (!result.success && result.errorMessage != null) {
      AppSnackbar.error(context, result.errorMessage!);
      return;
    }
    if (result.warningMessage != null) {
      AppSnackbar.info(context, result.warningMessage!);
    }
  }
}

class _CategoryTable extends StatefulWidget {
  const _CategoryTable({
    required this.categories,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final List<Category> categories;
  final Future<void> Function(List<String> ids) onReorder;
  final void Function(Category category) onEdit;
  final void Function(Category category) onDelete;
  final void Function(Category category) onToggleActive;

  @override
  State<_CategoryTable> createState() => _CategoryTableState();
}

class _CategoryTableState extends State<_CategoryTable> {
  late List<Category> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.categories);
  }

  @override
  void didUpdateWidget(covariant _CategoryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories != oldWidget.categories) {
      _items = List.of(widget.categories);
    }
  }

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
                SizedBox(width: spacing.lg),
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
                    'Image',
                    style: typography.labelLarge.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Active',
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
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _items.length,
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
                await widget.onReorder(_items.map((c) => c.id).toList());
              },
              itemBuilder: (context, index) {
                final category = _items[index];
                return _CategoryRow(
                  key: ValueKey(category.id),
                  category: category,
                  index: index,
                  onEdit: () => widget.onEdit(category),
                  onDelete: () => widget.onDelete(category),
                  onToggleActive: () => widget.onToggleActive(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.category,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Category category;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Material(
      color: colors.transparent,
      child: Column(
        key: key,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  flex: 3,
                  child: Text(
                    category.name,
                    style: typography.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _CategoryImageThumb(imageUrl: category.imageUrl),
                ),
                Expanded(
                  child: Switch(
                    value: category.isActive,
                    onChanged: (_) => onToggleActive(),
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
          ),
          Divider(height: 1, color: colors.divider, indent: spacing.md),
        ],
      ),
    );
  }
}

class _CategoryImageThumb extends StatelessWidget {
  const _CategoryImageThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final size = context.appSpacing.xl;
    return CatalogImage(
      url: imageUrl,
      width: size,
      height: size,
      borderRadius: context.appRadius.smBorder,
    );
  }
}
