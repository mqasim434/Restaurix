import '../../core/utils/date_range_utils.dart';
import '../models/salary_calculation.dart';
import '../models/salary_slip.dart';

class SalarySlipGenerationResult {
  const SalarySlipGenerationResult({
    required this.period,
    required this.createdCount,
    required this.skippedCount,
  });

  final SalaryPeriod period;
  final int createdCount;
  final int skippedCount;

  bool get didGenerate => createdCount > 0;
}

class SalaryAutoGenerationCheck {
  const SalaryAutoGenerationCheck({
    required this.shouldGenerate,
    required this.period,
    required this.generationDay,
  });

  final bool shouldGenerate;
  final SalaryPeriod period;
  final int generationDay;
}

abstract final class SalarySlipService {
  static SalaryPeriod priorCalendarMonthPeriod(DateTime anchor) {
    final thisMonthStart = startOfLocalMonth(anchor);
    final priorStart = DateTime(thisMonthStart.year, thisMonthStart.month - 1);
    return SalaryPeriod(
      startInclusive: priorStart,
      endExclusive: thisMonthStart,
    );
  }

  static SalaryPeriod periodFromRange(SalesDateRange range) {
    return SalaryPeriod(
      startInclusive: range.startInclusive,
      endExclusive: range.endExclusive,
    );
  }

  static DateTime inclusivePeriodEnd(SalaryPeriod period) {
    return localDateBucket(
      period.endExclusive.subtract(const Duration(days: 1)),
    );
  }

  static DateTime normalizedPeriodStart(SalaryPeriod period) {
    return localDateBucket(period.startInclusive);
  }

  static SalaryAutoGenerationCheck evaluateAutoGeneration({
    required int generationDay,
    required DateTime now,
    required bool priorPeriodAlreadyGenerated,
  }) {
    final clampedDay = generationDay.clamp(1, 28);
    final period = priorCalendarMonthPeriod(now);
    final shouldGenerate =
        now.day >= clampedDay && !priorPeriodAlreadyGenerated;

    return SalaryAutoGenerationCheck(
      shouldGenerate: shouldGenerate,
      period: period,
      generationDay: clampedDay,
    );
  }

  static List<SalarySlipDraftInput> buildDraftInputs({
    required SalaryCalculationResult calculation,
    required SalaryPeriod period,
  }) {
    final periodStart = normalizedPeriodStart(period);
    final periodEnd = inclusivePeriodEnd(period);

    return calculation.employees
        .map(
          (preview) => SalarySlipDraftInput(
            employeeId: preview.employee.id,
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalHours: preview.totalHours,
            basePay: preview.grossPay,
          ),
        )
        .toList();
  }
}

class SalarySlipDraftInput {
  const SalarySlipDraftInput({
    required this.employeeId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalHours,
    required this.basePay,
    this.deductions,
  });

  final String employeeId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalHours;
  final double basePay;
  final double? deductions;

  double get netPay => computeSalaryNetPay(
        basePay: basePay,
        deductions: deductions,
      );
}
