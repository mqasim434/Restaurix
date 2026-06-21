import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/product.dart';
import 'product_modifier_groups_tab.dart';
import 'product_variants_tab.dart';

class ProductFormResult {
  const ProductFormResult({
    required this.name,
    required this.categoryId,
    required this.basePrice,
    this.description,
    this.imageUrl,
    required this.isAvailable,
    required this.kitchenCategory,
    this.printerId,
    this.clearImage = false,
    this.clearPrinterId = false,
  });

  final String name;
  final String categoryId;
  final double basePrice;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final String kitchenCategory;
  final String? printerId;
  final bool clearImage;
  final bool clearPrinterId;
}

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    required this.categories,
    this.product,
  });

  final List<Category> categories;
  final Product? product;

  static Future<ProductFormResult?> show(
    BuildContext context, {
    required List<Category> categories,
    Product? product,
  }) {
    return showDialog<ProductFormResult>(
      context: context,
      builder: (context) => ProductFormDialog(
        categories: categories,
        product: product,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _kitchenCategoryController;
  late final TextEditingController _printerIdController;

  String? _categoryId;
  String? _imagePath;
  late bool _isAvailable;
  bool _clearedImage = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product != null
          ? widget.product!.basePrice.toStringAsFixed(2)
          : '',
    );
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _kitchenCategoryController = TextEditingController(
      text: widget.product?.kitchenCategory ?? '',
    );
    _printerIdController =
        TextEditingController(text: widget.product?.printerId ?? '');
    _categoryId = widget.product?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _imagePath = widget.product?.imageUrl;
    _isAvailable = widget.product?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _kitchenCategoryController.dispose();
    _printerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Product' : 'Add Product',
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: spacing.xxl * 9,
        height: spacing.xxl * 9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Variants'),
                Tab(text: 'Modifier Groups'),
              ],
            ),
            SizedBox(height: spacing.md),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(context),
                  _buildVariantsTab(context),
                  _buildModifierGroupsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: _isEditing ? 'Save' : 'Add',
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    if (widget.categories.isEmpty) {
      return Center(
        child: Text(
          'Create a category first before adding products.',
          style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'e.g. Classic Burger',
          ),
          SizedBox(height: spacing.md),
          AppDropdown<String>(
            label: 'Category',
            value: _categoryId,
            items: widget.categories.map((c) => c.id).toList(),
            itemLabel: (id) =>
                widget.categories.firstWhere((c) => c.id == id).name,
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          SizedBox(height: spacing.md),
          AppTextField(
            controller: _priceController,
            label: 'Base price',
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: spacing.md),
          AppTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Optional',
            maxLines: 3,
          ),
          SizedBox(height: spacing.md),
          AppTextField(
            controller: _kitchenCategoryController,
            label: 'Kitchen category',
            hint: 'e.g. Grill, Cold, Drinks',
          ),
          SizedBox(height: spacing.md),
          AppTextField(
            controller: _printerIdController,
            label: 'Printer ID',
            hint: 'Optional — configured in Settings (Module 29)',
          ),
          SizedBox(height: spacing.md),
          Text(
            'Image',
            style: typography.labelLarge.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: spacing.xs),
          Row(
            children: [
              _ProductThumbnail(path: _imagePath),
              SizedBox(width: spacing.md),
              Wrap(
                spacing: spacing.sm,
                children: [
                  AppButton(
                    label: 'Choose file',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.small,
                    onPressed: _pickImage,
                  ),
                  if (_imagePath != null)
                    AppButton(
                      label: 'Remove',
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.small,
                      onPressed: () => setState(() {
                        _imagePath = null;
                        _clearedImage = true;
                      }),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Available',
              style: typography.bodyMedium.copyWith(color: colors.onSurface),
            ),
            subtitle: Text(
              'Unavailable products are hidden from POS',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsTab(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    if (!_isEditing || widget.product == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Text(
            'Save the product first, then edit it to add variants.',
            style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ProductVariantsTab(
      productId: widget.product!.id,
      basePrice: () {
        final parsed = double.tryParse(_priceController.text.trim());
        return parsed ?? widget.product!.basePrice;
      },
    );
  }

  Widget _buildModifierGroupsTab(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    if (!_isEditing || widget.product == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Text(
            'Save the product first, then edit it to attach modifier groups.',
            style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ProductModifierGroupsTab(
      productId: widget.product!.id,
      assignedGroupIds: widget.product!.modifierGroupIds,
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _imagePath = result.files.single.path;
      _clearedImage = false;
    });
  }

  void _submit() {
    if (_categoryId == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price < 0) return;

    final printerText = _printerIdController.text.trim();

    Navigator.of(context).pop(
      ProductFormResult(
        name: name,
        categoryId: _categoryId!,
        basePrice: price,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: _imagePath,
        isAvailable: _isAvailable,
        kitchenCategory: _kitchenCategoryController.text.trim(),
        printerId: printerText.isEmpty ? null : printerText,
        clearImage: _clearedImage,
        clearPrinterId: printerText.isEmpty && _isEditing,
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final radius = context.appRadius;
    final spacing = context.appSpacing;
    final size = spacing.xxl + spacing.md;

    if (path != null && File(path!).existsSync()) {
      return ClipRRect(
        borderRadius: radius.mdBorder,
        child: Image.file(
          File(path!),
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
        borderRadius: radius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Icon(Icons.image_outlined, color: colors.onSurfaceVariant),
    );
  }
}

String formatProductPrice(double price) {
  return NumberFormat.simpleCurrency().format(price);
}
