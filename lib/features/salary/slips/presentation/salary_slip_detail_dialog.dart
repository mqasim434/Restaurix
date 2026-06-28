import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../domain/models/employee.dart';
import '../../../../domain/models/salary_slip.dart';
import '../../../settings/providers/settings_providers.dart';
import '../providers/salary_slip_providers.dart';
import '../salary_slip_preview.dart';

Future<void> showSalarySlipDetailDialog({
  required BuildContext context,
  required SalarySlip slip,
  required Employee employee,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => SalarySlipDetailDialog(
      slip: slip,
      employee: employee,
    ),
  );
}

class SalarySlipDetailDialog extends ConsumerStatefulWidget {
  const SalarySlipDetailDialog({
    super.key,
    required this.slip,
    required this.employee,
  });

  final SalarySlip slip;
  final Employee employee;

  @override
  ConsumerState<SalarySlipDetailDialog> createState() =>
      _SalarySlipDetailDialogState();
}

class _SalarySlipDetailDialogState extends ConsumerState<SalarySlipDetailDialog> {
  late final TextEditingController _deductionsController;
  late SalarySlip _slip;
  var _isSaving = false;
  var _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    _slip = widget.slip;
    _deductionsController = TextEditingController(
      text: _slip.deductions?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _deductionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final settings = ref.read(appSettingRepositoryProvider);

    return AlertDialog(
      title: Text('Salary slip — ${widget.employee.fullName}'),
      content: SizedBox(
        width: 480,
        child: FutureBuilder<String>(
          future: settings.getBusinessName(),
          builder: (context, snapshot) {
            final businessName = snapshot.data ?? 'Restaurix';
            final document = buildSalarySlipDocument(
              businessName: businessName,
              employee: widget.employee,
              slip: _slip,
            );
            final lines = SalarySlipPreview.renderLines(document);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceVariant,
                      borderRadius: context.appRadius.mdBorder,
                    ),
                    child: SelectableText(
                      lines.join('\n'),
                      style: typography.bodyMedium.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  if (!_slip.isFinalized) ...[
                    SizedBox(height: spacing.md),
                    AppTextField(
                      controller: _deductionsController,
                      label: 'Deductions (optional)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        AppButton(
          label: 'Copy',
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            final businessName = await settings.getBusinessName();
            final text = SalarySlipPreview.renderText(
              buildSalarySlipDocument(
                businessName: businessName,
                employee: widget.employee,
                slip: _slip,
              ),
            );
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            AppSnackbar.show(context, message: 'Slip copied to clipboard');
          },
        ),
        if (!_slip.isFinalized) ...[
          AppButton(
            label: 'Save deductions',
            variant: AppButtonVariant.secondary,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _saveDeductions,
          ),
          AppButton(
            label: 'Finalize',
            isLoading: _isFinalizing,
            onPressed: _isFinalizing ? null : _finalize,
          ),
        ],
      ],
    );
  }

  Future<void> _saveDeductions() async {
    setState(() => _isSaving = true);
    final parsed = double.tryParse(_deductionsController.text.trim());
    final deductions =
        _deductionsController.text.trim().isEmpty ? null : parsed;

    final result = await ref.read(salarySlipActionsProvider).updateDeductions(
          slipId: _slip.id,
          deductions: deductions,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      final updated = await ref
          .read(salarySlipRepositoryProvider)
          .findById(_slip.id);
      if (updated != null) {
        setState(() => _slip = updated);
      }
    }

    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: result.message ?? 'Update complete',
      type: result.success ? AppSnackbarType.success : AppSnackbarType.error,
    );
  }

  Future<void> _finalize() async {
    setState(() => _isFinalizing = true);
    final result =
        await ref.read(salarySlipActionsProvider).finalizeSlip(_slip.id);

    if (!mounted) return;
    setState(() => _isFinalizing = false);

    if (result.success) {
      final updated = await ref
          .read(salarySlipRepositoryProvider)
          .findById(_slip.id);
      if (updated != null) {
        setState(() => _slip = updated);
      }
    }

    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: result.message ?? 'Finalize complete',
      type: result.success ? AppSnackbarType.success : AppSnackbarType.error,
    );
  }
}
