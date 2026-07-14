import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../domain/models/employee.dart';
import '../../../../domain/models/salary_slip.dart';
import '../../../employees/providers/employee_providers.dart';
import '../../../settings/providers/currency_providers.dart';
import '../salary_slip_preview.dart';
import '../providers/salary_slip_providers.dart';
import 'salary_slip_detail_dialog.dart';

class SalarySlipsPanel extends ConsumerWidget {
  const SalarySlipsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final slipsAsync = ref.watch(salarySlipListProvider);
    final generationDayAsync = ref.watch(salaryGenerationDayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        generationDayAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (day) => Text(
            'Draft slips auto-generate on day $day of each month for the prior calendar month.',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        Row(
          children: [
            AppButton(
              label: 'Generate now',
              icon: Icons.receipt_long_outlined,
              onPressed: () => _generateNow(context, ref),
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        Expanded(
          child: slipsAsync.when(
            loading: () => const AppLoadingIndicator(
              message: 'Loading salary slips...',
            ),
            error: (error, _) => AppEmptyState(
              title: 'Failed to load salary slips',
              message: error.toString(),
            ),
            data: (slips) => _SlipList(slips: slips),
          ),
        ),
      ],
    );
  }

  Future<void> _generateNow(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(salarySlipActionsProvider).generateForCurrentFilter();
    if (!context.mounted) return;

    AppSnackbar.show(
      context,
      message: result.message ?? 'Generation complete',
      type: result.success ? AppSnackbarType.success : AppSnackbarType.error,
    );
  }
}

class _SlipList extends ConsumerWidget {
  const _SlipList({required this.slips});

  final List<SalarySlip> slips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (slips.isEmpty) {
      return const AppEmptyState(
        title: 'No salary slips yet',
        message:
            'Use Generate now after reviewing the calculation preview, or wait for the automatic monthly run.',
      );
    }

    final employeesAsync = ref.watch(employeeListProvider);
    return employeesAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading employees...'),
      error: (error, _) => AppEmptyState(
        title: 'Failed to load employees',
        message: error.toString(),
      ),
      data: (employees) {
        final employeeById = {for (final employee in employees) employee.id: employee};
        final grouped = _groupByPeriod(slips);

        return ListView.separated(
          itemCount: grouped.length,
          separatorBuilder: (_, __) => SizedBox(height: context.appSpacing.lg),
          itemBuilder: (context, index) {
            final entry = grouped[index];
            return _PeriodGroup(
              periodLabel: entry.label,
              slips: entry.slips,
              employeeById: employeeById,
            );
          },
        );
      },
    );
  }

  List<_PeriodGroupData> _groupByPeriod(List<SalarySlip> slips) {
    final map = <String, List<SalarySlip>>{};
    for (final slip in slips) {
      final key = '${slip.periodStart.toIso8601String()}|'
          '${slip.periodEnd.toIso8601String()}';
      map.putIfAbsent(key, () => []).add(slip);
    }

    final groups = map.entries.map((entry) {
      final first = entry.value.first;
      return _PeriodGroupData(
        label: formatSalaryPeriod(first.periodStart, first.periodEnd),
        slips: entry.value
          ..sort((a, b) => a.employeeId.compareTo(b.employeeId)),
      );
    }).toList()
      ..sort((a, b) => b.slips.first.periodStart.compareTo(a.slips.first.periodStart));

    return groups;
  }
}

class _PeriodGroupData {
  const _PeriodGroupData({
    required this.label,
    required this.slips,
  });

  final String label;
  final List<SalarySlip> slips;
}

class _PeriodGroup extends ConsumerWidget {
  const _PeriodGroup({
    required this.periodLabel,
    required this.slips,
    required this.employeeById,
  });

  final String periodLabel;
  final List<SalarySlip> slips;
  final Map<String, Employee> employeeById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final formatMoney = ref.watch(formatMoneyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          periodLabel,
          style: typography.titleMedium.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: spacing.sm),
        ...slips.map((slip) {
          final employee = employeeById[slip.employeeId];
          final name = employee?.fullName ?? slip.employeeId;
          return Card(
            margin: EdgeInsets.only(bottom: spacing.sm),
            child: ListTile(
              title: Text(name),
              subtitle: Text(
                '${slip.status.label} · ${slip.totalHours.toStringAsFixed(1)} h · '
                '${formatMoney(slip.netPay)} net',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: employee == null
                  ? null
                  : () => showSalarySlipDetailDialog(
                        context: context,
                        slip: slip,
                        employee: employee,
                      ),
            ),
          );
        }),
      ],
    );
  }
}
