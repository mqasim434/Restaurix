import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/catalog_image.dart';
import '../../../domain/models/pickup_company.dart';

class PickupCompanyFormResult {
  const PickupCompanyFormResult({
    required this.name,
    this.logoUrl,
    required this.isActive,
    this.clearLogo = false,
  });

  final String name;
  final String? logoUrl;
  final bool isActive;
  final bool clearLogo;
}

class PickupCompanyFormDialog extends StatefulWidget {
  const PickupCompanyFormDialog({
    super.key,
    this.company,
    this.title = 'Add Pickup Company',
  });

  final PickupCompany? company;
  final String title;

  static Future<PickupCompanyFormResult?> show(
    BuildContext context, {
    PickupCompany? company,
    String title = 'Add Pickup Company',
  }) {
    return showDialog<PickupCompanyFormResult>(
      context: context,
      builder: (context) =>
          PickupCompanyFormDialog(company: company, title: title),
    );
  }

  @override
  State<PickupCompanyFormDialog> createState() =>
      _PickupCompanyFormDialogState();
}

class _PickupCompanyFormDialogState extends State<PickupCompanyFormDialog> {
  late final TextEditingController _nameController;
  String? _logoPath;
  late bool _isActive;
  bool _clearedLogo = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?.name ?? '');
    _logoPath = widget.company?.logoUrl;
    _isActive = widget.company?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return AlertDialog(
      title: Text(
        widget.title,
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: spacing.xxl * 5,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Company name',
                hint: 'e.g. Foodpanda, Careem, Bykea',
              ),
              SizedBox(height: spacing.md),
              Text(
                'Logo',
                style: typography.labelLarge.copyWith(color: colors.onSurface),
              ),
              SizedBox(height: spacing.xs),
              Row(
                children: [
                  _LogoThumb(path: _logoPath),
                  SizedBox(width: spacing.md),
                  Wrap(
                    spacing: spacing.sm,
                    children: [
                      AppButton(
                        label: 'Choose file',
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.small,
                        onPressed: _pickLogo,
                      ),
                      if (_logoPath != null)
                        AppButton(
                          label: 'Remove',
                          variant: AppButtonVariant.ghost,
                          size: AppButtonSize.small,
                          onPressed: () => setState(() {
                            _logoPath = null;
                            _clearedLogo = true;
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
                  'Active',
                  style: typography.bodyMedium.copyWith(color: colors.onSurface),
                ),
                subtitle: Text(
                  'Inactive companies are hidden from POS delivery picker',
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
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _logoPath = result.files.single.path;
      _clearedLogo = false;
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.of(context).pop(
      PickupCompanyFormResult(
        name: name,
        logoUrl: _logoPath,
        isActive: _isActive,
        clearLogo: _clearedLogo,
      ),
    );
  }
}

class _LogoThumb extends StatelessWidget {
  const _LogoThumb({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final size = context.appSpacing.xxl;
    return CatalogImage(
      url: path,
      width: size,
      height: size,
      borderRadius: context.appRadius.smBorder,
      placeholderIcon: Icons.delivery_dining_outlined,
    );
  }
}