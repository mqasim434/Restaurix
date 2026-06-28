import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/app_settings.dart';
import '../../delivery_config/presentation/delivery_config_screen.dart';
import '../providers/settings_providers.dart';
import 'printer_config_form_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final settingsAsync = ref.watch(appSettingsProvider);

    return DefaultTabController(
      length: 4,
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Business profile, printers, delivery partners, and payroll automation',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'General'),
                Tab(text: 'Printers'),
                Tab(text: 'Pickup & Riders'),
                Tab(text: 'Salary'),
              ],
            ),
            SizedBox(height: spacing.md),
            Expanded(
              child: settingsAsync.when(
                loading: () => const AppLoadingIndicator(
                  message: 'Loading settings...',
                ),
                error: (error, _) => AppEmptyState(
                  title: 'Failed to load settings',
                  message: error.toString(),
                ),
                data: (settings) => TabBarView(
                  children: [
                    _GeneralPanel(settings: settings),
                    _PrintersPanel(settings: settings),
                    const _DeliveryPanel(),
                    _SalaryPanel(settings: settings),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralPanel extends ConsumerStatefulWidget {
  const _GeneralPanel({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_GeneralPanel> createState() => _GeneralPanelState();
}

class _GeneralPanelState extends ConsumerState<_GeneralPanel> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _headerController;
  late final TextEditingController _footerController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _businessNameController =
        TextEditingController(text: widget.settings.businessName);
    _addressController =
        TextEditingController(text: widget.settings.businessAddress ?? '');
    _headerController =
        TextEditingController(text: widget.settings.receiptHeaderText ?? '');
    _footerController =
        TextEditingController(text: widget.settings.receiptFooterText ?? '');
  }

  @override
  void didUpdateWidget(covariant _GeneralPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && !_isSaving) {
      _businessNameController.text = widget.settings.businessName;
      _addressController.text = widget.settings.businessAddress ?? '';
      _headerController.text = widget.settings.receiptHeaderText ?? '';
      _footerController.text = widget.settings.receiptFooterText ?? '';
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final businessName = _businessNameController.text.trim();
    if (businessName.isEmpty) {
      AppSnackbar.error(context, 'Business name is required.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = widget.settings.copyWith(
        businessName: businessName,
        businessAddress: _optionalText(_addressController.text),
        clearBusinessAddress: _addressController.text.trim().isEmpty,
        receiptHeaderText: _optionalText(_headerController.text),
        clearReceiptHeaderText: _headerController.text.trim().isEmpty,
        receiptFooterText: _optionalText(_footerController.text),
        clearReceiptFooterText: _footerController.text.trim().isEmpty,
      );
      await ref.read(settingsActionsProvider).save(updated);
      if (!mounted) return;
      AppSnackbar.success(context, 'General settings saved.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return ListView(
      children: [
        AppTextField(
          label: 'Business name',
          controller: _businessNameController,
        ),
        SizedBox(height: spacing.md),
        AppTextField(
          label: 'Business address',
          hint: 'Shown on customer receipts',
          controller: _addressController,
          maxLines: 2,
        ),
        SizedBox(height: spacing.md),
        AppTextField(
          label: 'Receipt header text',
          hint: 'Optional line below the business name',
          controller: _headerController,
          maxLines: 2,
        ),
        SizedBox(height: spacing.md),
        AppTextField(
          label: 'Receipt footer text',
          hint: 'Defaults to "Thank you!" when empty',
          controller: _footerController,
          maxLines: 2,
        ),
        SizedBox(height: spacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: _isSaving ? 'Saving...' : 'Save general settings',
            icon: AppIcons.check,
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ],
    );
  }
}

class _PrintersPanel extends ConsumerStatefulWidget {
  const _PrintersPanel({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_PrintersPanel> createState() => _PrintersPanelState();
}

class _CategoryMappingRow {
  _CategoryMappingRow({
    required this.categoryController,
    required this.printerRef,
  });

  final TextEditingController categoryController;
  String? printerRef;
}

class _PrintersPanelState extends ConsumerState<_PrintersPanel> {
  String? _receiptPrinterRef;
  String? _kitchenDefaultRef;
  final List<_CategoryMappingRow> _categoryRows = [];
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.settings);
  }

  @override
  void didUpdateWidget(covariant _PrintersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && !_isSaving) {
      _syncFrom(widget.settings);
    }
  }

  void _syncFrom(AppSettings settings) {
    _receiptPrinterRef = settings.receiptPrinterTarget;
    _kitchenDefaultRef = settings.kitchenDefaultPrinterTarget;
    for (final row in _categoryRows) {
      row.categoryController.dispose();
    }
    _categoryRows
      ..clear()
      ..addAll(
        settings.kitchenCategoryPrinters.entries.map(
          (entry) => _CategoryMappingRow(
            categoryController: TextEditingController(text: entry.key),
            printerRef: entry.value.isEmpty ? null : entry.value,
          ),
        ),
      );
  }

  Map<String, String> _categoryPrintersFromRows() {
    final map = <String, String>{};
    for (final row in _categoryRows) {
      final category = row.categoryController.text.trim();
      final printerRef = row.printerRef?.trim();
      if (category.isEmpty || printerRef == null || printerRef.isEmpty) {
        continue;
      }
      map[category] = printerRef;
    }
    return map;
  }

  Future<void> _saveRouting() async {
    setState(() => _isSaving = true);
    try {
      final updated = widget.settings.copyWith(
        receiptPrinterTarget: _receiptPrinterRef,
        clearReceiptPrinterTarget: _receiptPrinterRef == null,
        kitchenDefaultPrinterTarget: _kitchenDefaultRef,
        clearKitchenDefaultPrinterTarget: _kitchenDefaultRef == null,
        kitchenCategoryPrinters: _categoryPrintersFromRows(),
      );
      await ref.read(settingsActionsProvider).save(updated);
      if (!mounted) return;
      AppSnackbar.success(context, 'Printer routing saved.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addOrEditPrinter({PrinterConfig? printer}) async {
    final result = await PrinterConfigFormDialog.show(
      context,
      printer: printer,
      title: printer == null ? 'Add Printer' : 'Edit Printer',
    );
    if (result == null || !mounted) return;

    final next = List<PrinterConfig>.from(widget.settings.printers);
    if (printer == null) {
      next.add(buildPrinterConfig(result: result));
    } else {
      final index = next.indexWhere((entry) => entry.id == printer.id);
      if (index >= 0) {
        next[index] = buildPrinterConfig(result: result, existing: printer);
      }
    }

    await ref.read(settingsActionsProvider).save(
          widget.settings.copyWith(printers: next),
        );
  }

  Future<void> _deletePrinter(PrinterConfig printer) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete printer?',
      content: Text(
        'Remove "${printer.name}" from saved printer configs?',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (confirmed != true || !mounted) return;

    final nextPrinters =
        widget.settings.printers.where((entry) => entry.id != printer.id).toList();
    var nextSettings = widget.settings.copyWith(printers: nextPrinters);

    if (_receiptPrinterRef == printer.id) {
      _receiptPrinterRef = null;
      nextSettings = nextSettings.copyWith(clearReceiptPrinterTarget: true);
    }
    if (_kitchenDefaultRef == printer.id) {
      _kitchenDefaultRef = null;
      nextSettings = nextSettings.copyWith(clearKitchenDefaultPrinterTarget: true);
    }

    final cleanedCategoryMap = _categoryPrintersFromRows()
      ..removeWhere((_, value) => value == printer.id);
    for (final row in _categoryRows) {
      if (row.printerRef == printer.id) {
        row.printerRef = null;
      }
    }
    nextSettings = nextSettings.copyWith(
      kitchenCategoryPrinters: cleanedCategoryMap,
    );

    await ref.read(settingsActionsProvider).save(nextSettings);
  }

  void _addCategoryMapping() {
    setState(() {
      _categoryRows.add(
        _CategoryMappingRow(
          categoryController: TextEditingController(),
          printerRef: widget.settings.printers.isNotEmpty
              ? widget.settings.printers.first.id
              : null,
        ),
      );
    });
  }

  @override
  void dispose() {
    for (final row in _categoryRows) {
      row.categoryController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final printers = widget.settings.printers;

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Named printer configs',
                style: typography.titleSmall,
              ),
            ),
            AppButton(
              label: 'Add printer',
              icon: AppIcons.add,
              size: AppButtonSize.small,
              onPressed: () => _addOrEditPrinter(),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        if (printers.isEmpty)
          AppEmptyState(
            title: 'No printers configured',
            message:
                'Add a printer config with a Windows name or network target.',
            actionLabel: 'Add printer',
            onAction: () => _addOrEditPrinter(),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: context.appRadius.mdBorder,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < printers.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.divider),
                  ListTile(
                    title: Text(printers[i].name),
                    subtitle: Text(printers[i].target),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: Icon(AppIcons.edit,
                              color: colors.onSurfaceVariant),
                          onPressed: () =>
                              _addOrEditPrinter(printer: printers[i]),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: Icon(AppIcons.delete, color: colors.error),
                          onPressed: () => _deletePrinter(printers[i]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        SizedBox(height: spacing.lg),
        Text('Default routing', style: typography.titleSmall),
        SizedBox(height: spacing.sm),
        _PrinterReferenceDropdown(
          label: 'Receipt printer',
          printers: printers,
          value: _receiptPrinterRef,
          onChanged: (value) => setState(() => _receiptPrinterRef = value),
        ),
        SizedBox(height: spacing.md),
        _PrinterReferenceDropdown(
          label: 'Kitchen default printer',
          printers: printers,
          value: _kitchenDefaultRef,
          onChanged: (value) => setState(() => _kitchenDefaultRef = value),
        ),
        SizedBox(height: spacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Kitchen category routing',
                style: typography.titleSmall,
              ),
            ),
            AppButton(
              label: 'Add mapping',
              icon: AppIcons.add,
              size: AppButtonSize.small,
              onPressed: printers.isEmpty ? null : _addCategoryMapping,
            ),
          ],
        ),
        SizedBox(height: spacing.xs),
        Text(
          'Used when a product has a kitchen category but no product-level printer.',
          style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: spacing.sm),
        if (_categoryRows.isEmpty)
          Text(
            'No category mappings yet.',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        else
          ..._categoryRows.map((row) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Kitchen category',
                      hint: 'Grill, Bar, Cold...',
                      controller: row.categoryController,
                    ),
                  ),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: _PrinterReferenceDropdown(
                      label: 'Printer',
                      printers: printers,
                      value: row.printerRef,
                      onChanged: (value) {
                        setState(() => row.printerRef = value);
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove mapping',
                    icon: Icon(AppIcons.delete, color: colors.error),
                    onPressed: () {
                      setState(() {
                        row.categoryController.dispose();
                        _categoryRows.remove(row);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        SizedBox(height: spacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: _isSaving ? 'Saving...' : 'Save printer routing',
            icon: AppIcons.check,
            onPressed: _isSaving ? null : _saveRouting,
          ),
        ),
      ],
    );
  }
}

class _PrinterReferenceDropdown extends StatelessWidget {
  const _PrinterReferenceDropdown({
    required this.label,
    required this.printers,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<PrinterConfig> printers;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <String?>[null, ...printers.map((printer) => printer.id)];

    String labelFor(String? reference) {
      if (reference == null) return '(None)';
      for (final printer in printers) {
        if (printer.id == reference) {
          return '${printer.name} (${printer.target})';
        }
      }
      return 'Custom: $reference';
    }

    return AppDropdown<String?>(
      label: label,
      value: value,
      items: items,
      itemLabel: labelFor,
      onChanged: onChanged,
    );
  }
}

class _DeliveryPanel extends StatelessWidget {
  const _DeliveryPanel();

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Riders'),
              Tab(text: 'Pickup Companies'),
            ],
          ),
          SizedBox(height: spacing.md),
          const Expanded(
            child: TabBarView(
              children: [
                DeliveryRidersPanel(),
                DeliveryPickupCompaniesPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryPanel extends ConsumerStatefulWidget {
  const _SalaryPanel({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_SalaryPanel> createState() => _SalaryPanelState();
}

class _SalaryPanelState extends ConsumerState<_SalaryPanel> {
  late int _generationDay;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generationDay = widget.settings.salaryGenerationDay;
  }

  @override
  void didUpdateWidget(covariant _SalaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && !_isSaving) {
      _generationDay = widget.settings.salaryGenerationDay;
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(settingsActionsProvider).save(
            widget.settings.copyWith(salaryGenerationDay: _generationDay),
          );
      if (!mounted) return;
      AppSnackbar.success(context, 'Salary generation day saved.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final days = List<int>.generate(28, (index) => index + 1);

    return ListView(
      children: [
        Text(
          'Automatic salary slip generation',
          style: typography.titleSmall,
        ),
        SizedBox(height: spacing.sm),
        Text(
          'On the selected day each month, Restaurix creates draft salary slips '
          'for the prior calendar month when the app starts.',
          style: typography.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.lg),
        AppDropdown<int>(
          label: 'Generation day of month',
          value: _generationDay,
          items: days,
          itemLabel: (day) => 'Day $day',
          onChanged: (value) {
            if (value != null) setState(() => _generationDay = value);
          },
        ),
        SizedBox(height: spacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: _isSaving ? 'Saving...' : 'Save salary settings',
            icon: AppIcons.check,
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ],
    );
  }
}
