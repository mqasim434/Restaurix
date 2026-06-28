import '../models/employee.dart';

enum SalaryCalculationMode {
  /// Excludes open shifts — use for payroll-final numbers.
  finalPayroll,

  /// Includes open shifts up to [asOf] — use for live estimates.
  liveEstimate,
}

extension SalaryCalculationModeX on SalaryCalculationMode {
  String get label => switch (this) {
        SalaryCalculationMode.finalPayroll => 'Final payroll',
        SalaryCalculationMode.liveEstimate => 'Live estimate',
      };
}

class SalaryPeriod {
  const SalaryPeriod({
    required this.startInclusive,
    required this.endExclusive,
  });

  final DateTime startInclusive;
  final DateTime endExclusive;
}

class EmployeeSalaryPreview {
  const EmployeeSalaryPreview({
    required this.employee,
    required this.totalHours,
    required this.closedShiftCount,
    required this.openShiftCountIncluded,
    required this.grossPay,
    required this.isProratedMonthly,
    required this.payDescription,
  });

  final Employee employee;
  final double totalHours;
  final int closedShiftCount;
  final int openShiftCountIncluded;
  final double grossPay;
  final bool isProratedMonthly;
  final String payDescription;
}

class SalaryCalculationResult {
  const SalaryCalculationResult({
    required this.period,
    required this.mode,
    required this.employees,
  });

  final SalaryPeriod period;
  final SalaryCalculationMode mode;
  final List<EmployeeSalaryPreview> employees;

  double get totalGrossPay =>
      employees.fold(0, (sum, row) => sum + row.grossPay);

  double get totalHours =>
      employees.fold(0, (sum, row) => sum + row.totalHours);
}
