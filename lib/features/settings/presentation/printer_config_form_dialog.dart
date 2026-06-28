import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/app_settings.dart';

class PrinterConfigFormResult {
  const PrinterConfigFormResult({
    required this.name,
    required this.target,
  });

  final String name;
  final String target;
}

class PrinterConfigFormDialog extends StatefulWidget {
  const PrinterConfigFormDialog({
    super.key,
    this.printer,
    this.title = 'Add Printer',
  });

  final PrinterConfig? printer;
  final String title;

  static Future<PrinterConfigFormResult?> show(
    BuildContext context, {
    PrinterConfig? printer,
    String title = 'Add Printer',
  }) {
    return showDialog<PrinterConfigFormResult>(
      context: context,
      builder: (context) =>
          PrinterConfigFormDialog(printer: printer, title: title),
    );
  }

  @override
  State<PrinterConfigFormDialog> createState() =>
      _PrinterConfigFormDialogState();
}

class _PrinterConfigFormDialogState extends State<PrinterConfigFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.printer?.name ?? '');
    _targetController =
        TextEditingController(text: widget.printer?.target ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final target = _targetController.text.trim();
    if (name.isEmpty || target.isEmpty) {
      setState(() {
        _errorMessage = 'Name and printer target are required.';
      });
      return;
    }

    Navigator.of(context).pop(
      PrinterConfigFormResult(name: name, target: target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Display name',
              hint: 'Kitchen main',
              controller: _nameController,
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              label: 'Printer target',
              hint: 'Windows printer name or network IP/host',
              controller: _targetController,
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: spacing.sm),
              Text(
                _errorMessage!,
                style: typography.bodySmall.copyWith(color: colors.error),
              ),
            ],
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
          label: widget.printer == null ? 'Add' : 'Save',
          onPressed: _submit,
        ),
      ],
    );
  }
}

PrinterConfig buildPrinterConfig({
  required PrinterConfigFormResult result,
  PrinterConfig? existing,
}) {
  return PrinterConfig(
    id: existing?.id ?? const Uuid().v4(),
    name: result.name,
    target: result.target,
  );
}
