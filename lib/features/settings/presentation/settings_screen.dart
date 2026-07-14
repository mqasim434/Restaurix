import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/debug/demo_data_seeder.dart';
import '../../../core/theme/app_icons.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/app_currency.dart';
import '../../../domain/models/app_settings.dart';
import '../../delivery_config/presentation/delivery_config_screen.dart';
import '../providers/settings_providers.dart';

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
              'Business profile, delivery partners, and payroll automation',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'General'),
                Tab(text: 'Pickup & Riders'),
                Tab(text: 'Salary'),
                Tab(text: 'Developer'),
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
                    const _DeliveryPanel(),
                    _SalaryPanel(settings: settings),
                    const _DeveloperPanel(),
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
  late String _currencyCode;
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
    _currencyCode = widget.settings.currencyCode;
  }

  @override
  void didUpdateWidget(covariant _GeneralPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && !_isSaving) {
      _businessNameController.text = widget.settings.businessName;
      _addressController.text = widget.settings.businessAddress ?? '';
      _headerController.text = widget.settings.receiptHeaderText ?? '';
      _footerController.text = widget.settings.receiptFooterText ?? '';
      _currencyCode = widget.settings.currencyCode;
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
        currencyCode: _currencyCode,
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
        SizedBox(height: spacing.md),
        AppDropdown<String>(
          label: 'Currency',
          hint: 'Used for prices, sales, and receipts',
          value: _currencyCode,
          items: AppCurrency.options.map((option) => option.code).toList(),
          itemLabel: (code) =>
              AppCurrency.options.firstWhere((option) => option.code == code).label,
          onChanged: (value) {
            if (value != null) setState(() => _currencyCode = value);
          },
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

class _DeveloperPanel extends ConsumerStatefulWidget {
  const _DeveloperPanel();

  @override
  ConsumerState<_DeveloperPanel> createState() => _DeveloperPanelState();
}

class _DeveloperPanelState extends ConsumerState<_DeveloperPanel> {
  var _isSeeding = false;
  DemoDataSeedResult? _lastResult;

  Future<void> _seedDemoData() async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Generate demo dataset?',
      content: Text(
        'This adds categories, products, employees, ~${90 * 20} orders over '
        '90 days, and attendance records to the local database. Existing data '
        'is kept — new records are appended.',
      ),
      confirmLabel: 'Generate',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);
    try {
      final isar = ref.read(isarServiceProvider).instance;
      final deviceId = ref.read(deviceIdProvider);
      final result = await DemoDataSeeder(
        isar: isar,
        deviceId: deviceId,
      ).seed();
      if (!mounted) return;
      setState(() => _lastResult = result);
      AppSnackbar.success(
        context,
        'Demo data ready: ${result.totalRecords} records in '
        '${result.elapsed.inMilliseconds}ms',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Demo seed failed: $error');
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final last = _lastResult;

    return ListView(
      children: [
        Text(
          'Regression & performance tools',
          style: typography.titleSmall,
        ),
        SizedBox(height: spacing.sm),
        Text(
          'Use demo data to stress-test dashboard, reports, orders pagination, '
          'and offline analytics without manual entry. Seeded records are marked '
          'synced so they do not inflate the pending sync badge.',
          style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: spacing.lg),
        AppButton(
          label: _isSeeding ? 'Generating demo data...' : 'Generate demo dataset',
          icon: AppIcons.add,
          onPressed: _isSeeding ? null : _seedDemoData,
        ),
        if (last != null) ...[
          SizedBox(height: spacing.lg),
          Text('Last run', style: typography.titleSmall),
          SizedBox(height: spacing.sm),
          Text(
            '${last.categories} categories · ${last.products} products · '
            '${last.employees} employees · ${last.orders} orders · '
            '${last.orderItems} line items · ${last.attendanceRecords} attendance',
            style: typography.bodyMedium,
          ),
          SizedBox(height: spacing.xs),
          Text(
            'Completed in ${last.elapsed.inMilliseconds}ms',
            style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
