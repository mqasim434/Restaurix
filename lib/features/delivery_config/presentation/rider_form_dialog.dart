import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/rider.dart';

class RiderFormResult {
  const RiderFormResult({
    required this.name,
    this.phone,
    required this.isActive,
    this.clearPhone = false,
  });

  final String name;
  final String? phone;
  final bool isActive;
  final bool clearPhone;
}

class RiderFormDialog extends StatefulWidget {
  const RiderFormDialog({
    super.key,
    this.rider,
    this.title = 'Add Rider',
  });

  final Rider? rider;
  final String title;

  static Future<RiderFormResult?> show(
    BuildContext context, {
    Rider? rider,
    String title = 'Add Rider',
  }) {
    return showDialog<RiderFormResult>(
      context: context,
      builder: (context) => RiderFormDialog(rider: rider, title: title),
    );
  }

  @override
  State<RiderFormDialog> createState() => _RiderFormDialogState();
}

class _RiderFormDialogState extends State<RiderFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rider?.name ?? '');
    _phoneController = TextEditingController(text: widget.rider?.phone ?? '');
    _isActive = widget.rider?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Rider name',
              hint: 'e.g. Ali Khan',
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              controller: _phoneController,
              label: 'Phone',
              hint: 'Optional',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: spacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Active',
                style: typography.bodyMedium.copyWith(color: colors.onSurface),
              ),
              subtitle: Text(
                'Inactive riders are hidden from POS delivery picker',
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
          label: 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final phoneText = _phoneController.text.trim();

    Navigator.of(context).pop(
      RiderFormResult(
        name: name,
        phone: phoneText.isEmpty ? null : phoneText,
        isActive: _isActive,
        clearPhone: phoneText.isEmpty && widget.rider != null,
      ),
    );
  }
}
