import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/modifier_group.dart';
import '../../../domain/models/modifier_selection_type.dart';

class ModifierGroupFormResult {
  const ModifierGroupFormResult({
    required this.name,
    required this.selectionType,
    required this.isRequired,
    required this.minSelections,
    this.maxSelections,
    this.clearMaxSelections = false,
  });

  final String name;
  final ModifierSelectionType selectionType;
  final bool isRequired;
  final int minSelections;
  final int? maxSelections;
  final bool clearMaxSelections;
}

class ModifierGroupFormDialog extends StatefulWidget {
  const ModifierGroupFormDialog({
    super.key,
    this.group,
    this.title = 'Add Modifier Group',
  });

  final ModifierGroup? group;
  final String title;

  static Future<ModifierGroupFormResult?> show(
    BuildContext context, {
    ModifierGroup? group,
    String title = 'Add Modifier Group',
  }) {
    return showDialog<ModifierGroupFormResult>(
      context: context,
      builder: (context) => ModifierGroupFormDialog(group: group, title: title),
    );
  }

  @override
  State<ModifierGroupFormDialog> createState() =>
      _ModifierGroupFormDialogState();
}

class _ModifierGroupFormDialogState extends State<ModifierGroupFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late ModifierSelectionType _selectionType;
  late bool _isRequired;
  late bool _hasMaxLimit;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _minController = TextEditingController(
      text: group?.minSelections.toString() ?? '0',
    );
    _maxController = TextEditingController(
      text: group?.maxSelections?.toString() ?? '',
    );
    _selectionType =
        group?.selectionType ?? ModifierSelectionType.multiple;
    _isRequired = group?.isRequired ?? false;
    _hasMaxLimit = group?.maxSelections != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
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
        width: spacing.xxl * 6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Group name',
                hint: 'e.g. Extras, Spice Level',
              ),
              SizedBox(height: spacing.md),
              AppDropdown<ModifierSelectionType>(
                label: 'Selection type',
                value: _selectionType,
                items: ModifierSelectionType.values,
                itemLabel: (type) => type.label,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectionType = value;
                    if (value == ModifierSelectionType.single) {
                      _hasMaxLimit = true;
                      _maxController.text = '1';
                    }
                  });
                },
              ),
              SizedBox(height: spacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Required at POS',
                  style: typography.bodyMedium.copyWith(color: colors.onSurface),
                ),
                subtitle: Text(
                  'Customers must pick from this group before adding to cart',
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                value: _isRequired,
                onChanged: (value) => setState(() {
                  _isRequired = value;
                  if (value && (_minController.text.trim().isEmpty ||
                      int.tryParse(_minController.text.trim()) == 0)) {
                    _minController.text = '1';
                  }
                }),
              ),
              SizedBox(height: spacing.sm),
              AppTextField(
                controller: _minController,
                label: 'Minimum selections',
                hint: '0',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: spacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Limit maximum selections',
                  style: typography.bodyMedium.copyWith(color: colors.onSurface),
                ),
                value: _hasMaxLimit,
                onChanged: _selectionType == ModifierSelectionType.single
                    ? null
                    : (value) => setState(() => _hasMaxLimit = value),
              ),
              if (_hasMaxLimit) ...[
                SizedBox(height: spacing.sm),
                AppTextField(
                  controller: _maxController,
                  label: 'Maximum selections',
                  hint: 'Leave blank for unlimited',
                  keyboardType: TextInputType.number,
                  enabled: _selectionType != ModifierSelectionType.single,
                ),
              ],
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

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final minSelections = int.tryParse(_minController.text.trim()) ?? 0;
    if (minSelections < 0) return;

    int? maxSelections;
    if (_selectionType == ModifierSelectionType.single) {
      maxSelections = 1;
    } else if (_hasMaxLimit) {
      final parsed = int.tryParse(_maxController.text.trim());
      if (parsed == null || parsed < 0) return;
      maxSelections = parsed;
    }

    if (maxSelections != null && maxSelections < minSelections) return;

    Navigator.of(context).pop(
      ModifierGroupFormResult(
        name: name,
        selectionType: _selectionType,
        isRequired: _isRequired,
        minSelections: minSelections,
        maxSelections: maxSelections,
        clearMaxSelections: !_hasMaxLimit &&
            _selectionType != ModifierSelectionType.single,
      ),
    );
  }
}
