import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../domain/models/employee.dart';
import '../../../../domain/models/salary_calculation.dart';
import '../../../reports/presentation/widgets/date_range_selector_bar.dart';
import '../../../settings/providers/currency_providers.dart';
import '../../slips/providers/salary_slip_providers.dart';
import '../providers/salary_calculation_providers.dart';

class SalaryCalculationScreen extends ConsumerWidget {
  const SalaryCalculationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final filter = ref.watch(salaryFilterProvider);
    final range = filter.resolve();
    final resultAsync = ref.watch(salaryCalculationProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preview gross pay from attendance hours before generating salary slips',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.md),
          DateRangeSelectorBar(
            filter: filter.toDateRangeFilter(),
            rangeLabel: salesDateRangeLabel(range),
            onPresetSelected: (preset) {
              ref.read(salaryFilterProvider.notifier).state =
                  filter.copyWith(preset: preset, clearCustomDates: true);
            },
            onCustomRangeSelected: (start, end) {
              ref.read(salaryFilterProvider.notifier).state = SalaryFilterState(
                preset: SalesDateRangePreset.custom,
                customStart: start,
                customEnd: end,
                mode: filter.mode,
              );
            },
          ),
          SizedBox(height: spacing.md),
          _ModeSelector(
            mode: filter.mode,
            onChanged: (mode) {
              ref.read(salaryFilterProvider.notifier).state =
                  filter.copyWith(mode: mode);
            },
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: resultAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Calculating salaries...',
              ),
              error: (error, _) => AppEmptyState(
                title: 'Failed to calculate salaries',
                message: error.toString(),
              ),
              data: (result) => _SalaryPreviewContent(result: result),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.onChanged,
  });

  final SalaryCalculationMode mode;
  final ValueChanged<SalaryCalculationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Wrap(
      spacing: spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Calculation mode',
          style: context.appTypography.labelLarge.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SegmentedButton<SalaryCalculationMode>(
          segments: SalaryCalculationMode.values
              .map(
                (value) => ButtonSegment(
                  value: value,
                  label: Text(value.label),
                ),
              )
              .toList(),
          selected: {mode},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class _SalaryPreviewContent extends ConsumerWidget {
  const _SalaryPreviewContent({required this.result});

  final SalaryCalculationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final currency = ref.watch(moneyNumberFormatProvider);

    if (result.employees.isEmpty) {
      return const AppEmptyState(
        title: 'No employees',
        message: 'Add employees before previewing salary calculations.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SummaryChip(
              label: 'Total gross pay',
              value: currency.format(result.totalGrossPay),
            ),
            _SummaryChip(
              label: 'Total hours',
              value: '${result.totalHours.toStringAsFixed(1)} h',
            ),
            _SummaryChip(
              label: 'Employees',
              value: '${result.employees.length}',
            ),
            AppButton(
              label: 'Generate draft slips',
              icon: Icons.receipt_long_outlined,
              onPressed: () async {
                final mutation =
                    await ref.read(salarySlipActionsProvider).generateForCurrentFilter();
                if (!context.mounted) return;
                AppSnackbar.show(
                  context,
                  message: mutation.message ?? 'Generation complete',
                  type: mutation.success
                      ? AppSnackbarType.success
                      : AppSnackbarType.error,
                );
              },
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        Expanded(
          child: AppCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: typography.labelLarge.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  columns: const [
                    DataColumn(label: Text('Employee')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Pay type')),
                    DataColumn(label: Text('Hours')),
                    DataColumn(label: Text('Closed shifts')),
                    DataColumn(label: Text('Open included')),
                    DataColumn(label: Text('Gross pay')),
                    DataColumn(label: Text('Notes')),
                  ],
                  rows: result.employees.map((preview) {
                    return DataRow(
                      cells: [
                        DataCell(Text(preview.employee.fullName)),
                        DataCell(Text(preview.employee.role)),
                        DataCell(Text(preview.employee.payType.label)),
                        DataCell(Text(
                          preview.totalHours.toStringAsFixed(1),
                        )),
                        DataCell(Text('${preview.closedShiftCount}')),
                        DataCell(Text('${preview.openShiftCountIncluded}')),
                        DataCell(Text(currency.format(preview.grossPay))),
                        DataCell(Text(preview.payDescription)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return AppCard(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: typography.labelMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              value,
              style: typography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
