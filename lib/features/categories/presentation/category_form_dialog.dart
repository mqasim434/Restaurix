import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/catalog_image.dart';
import '../../../domain/models/category.dart';

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({
    super.key,
    this.category,
  });

  final Category? category;

  static Future<CategoryFormResult?> show(
    BuildContext context, {
    Category? category,
  }) {
    return showDialog<CategoryFormResult>(
      context: context,
      builder: (context) => CategoryFormDialog(category: category),
    );
  }

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class CategoryFormResult {
  const CategoryFormResult({
    required this.name,
    this.imageUrl,
    required this.isActive,
    this.clearImage = false,
  });

  final String name;
  final String? imageUrl;
  final bool isActive;
  final bool clearImage;
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final TextEditingController _nameController;
  String? _imagePath;
  late bool _isActive;
  bool _clearedImage = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _imagePath = widget.category?.imageUrl;
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Category' : 'Add Category',
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: spacing.xxl * 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'e.g. Burgers',
            ),
            SizedBox(height: spacing.md),
            Text(
              'Image',
              style: typography.labelLarge.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.xs),
            Row(
              children: [
                _CategoryThumbnail(path: _imagePath),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Wrap(
                    spacing: spacing.sm,
                    runSpacing: spacing.sm,
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
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Active',
                style: typography.bodyMedium.copyWith(color: colors.onSurface),
              ),
              subtitle: Text(
                'Inactive categories are hidden from POS',
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
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
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.of(context).pop(
      CategoryFormResult(
        name: name,
        imageUrl: _imagePath,
        isActive: _isActive,
        clearImage: _clearedImage,
      ),
    );
  }
}

class _CategoryThumbnail extends StatelessWidget {
  const _CategoryThumbnail({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final size = context.appSpacing.xxl + context.appSpacing.md;
    return CatalogImage(
      url: path,
      width: size,
      height: size,
      borderRadius: context.appRadius.mdBorder,
    );
  }
}
