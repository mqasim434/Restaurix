import '../../core/utils/date_range_utils.dart';
import '../models/attendance_record.dart';
import '../models/employee.dart';
import '../models/salary_calculation.dart';

/// Computes hours and gross pay from attendance records.
///
/// Monthly proration uses Monday–Friday working days in the selected period
/// divided by Monday–Friday working days in the calendar month that contains
/// the period start.
abstract final class SalaryCalculationService {
  static SalaryCalculationResult calculate({
    required SalaryPeriod period,
    required SalaryCalculationMode mode,
    required List<Employee> employees,
    required List<AttendanceRecord> attendanceRecords,
    DateTime? asOf,
  }) {
    final anchor = asOf ?? DateTime.now();
    final previews = employees
        .map(
          (employee) => _calculateEmployee(
            employee: employee,
            period: period,
            mode: mode,
            records: attendanceRecords
                .where((record) => record.employeeId == employee.id)
                .toList(),
            asOf: anchor,
          ),
        )
        .toList()
      ..sort((a, b) => a.employee.fullName.compareTo(b.employee.fullName));

    return SalaryCalculationResult(
      period: period,
      mode: mode,
      employees: previews,
    );
  }

  static EmployeeSalaryPreview _calculateEmployee({
    required Employee employee,
    required SalaryPeriod period,
    required SalaryCalculationMode mode,
    required List<AttendanceRecord> records,
    required DateTime asOf,
  }) {
    final inRange = records.where((record) {
      return !record.checkInTime.isBefore(period.startInclusive) &&
          record.checkInTime.isBefore(period.endExclusive);
    });

    var totalMinutes = 0;
    var closedCount = 0;
    var openIncluded = 0;

    for (final record in inRange) {
      final duration = _resolveDuration(
        record: record,
        mode: mode,
        asOf: asOf,
      );
      if (duration == null) continue;

      totalMinutes += duration.inMinutes;
      if (record.isOpen) {
        openIncluded += 1;
      } else {
        closedCount += 1;
      }
    }

    final totalHours = totalMinutes / 60;
    final pay = _calculateGrossPay(
      employee: employee,
      period: period,
      totalHours: totalHours,
    );

    return EmployeeSalaryPreview(
      employee: employee,
      totalHours: totalHours,
      closedShiftCount: closedCount,
      openShiftCountIncluded: openIncluded,
      grossPay: pay.amount,
      isProratedMonthly: pay.isProrated,
      payDescription: pay.description,
    );
  }

  static Duration? _resolveDuration({
    required AttendanceRecord record,
    required SalaryCalculationMode mode,
    required DateTime asOf,
  }) {
    if (!record.isOpen) {
      return record.workedDuration();
    }

    if (mode == SalaryCalculationMode.finalPayroll) {
      return null;
    }

    return record.workedDuration(until: asOf);
  }

  static _PayBreakdown _calculateGrossPay({
    required Employee employee,
    required SalaryPeriod period,
    required double totalHours,
  }) {
    return switch (employee.payType) {
      EmployeePayType.hourly => _hourlyPay(employee, totalHours),
      EmployeePayType.monthly => _monthlyPay(employee, period),
    };
  }

  static _PayBreakdown _hourlyPay(Employee employee, double totalHours) {
    final rate = employee.hourlyRate ?? 0;
    final amount = totalHours * rate;
    return _PayBreakdown(
      amount: amount,
      isProrated: false,
      description: '${totalHours.toStringAsFixed(1)} h × '
          '${rate.toStringAsFixed(2)}/hr',
    );
  }

  static _PayBreakdown _monthlyPay(Employee employee, SalaryPeriod period) {
    final base = employee.monthlySalaryBase ?? 0;
    if (_isFullCalendarMonth(period)) {
      return _PayBreakdown(
        amount: base,
        isProrated: false,
        description: 'Full month salary',
      );
    }

    final monthStart = startOfLocalMonth(period.startInclusive);
    final monthEnd = endOfLocalMonthExclusive(monthStart);
    final workingDaysInMonth =
        countStandardWorkingDays(monthStart, monthEnd);
    final workingDaysInPeriod = countStandardWorkingDays(
      period.startInclusive,
      period.endExclusive,
    );

    if (workingDaysInMonth == 0) {
      return _PayBreakdown(
        amount: 0,
        isProrated: true,
        description: 'No working days in month',
      );
    }

    final amount = base * (workingDaysInPeriod / workingDaysInMonth);
    return _PayBreakdown(
      amount: amount,
      isProrated: true,
      description:
          '$workingDaysInPeriod of $workingDaysInMonth working days prorated',
    );
  }

  static bool _isFullCalendarMonth(SalaryPeriod period) {
    final start = localDateBucket(period.startInclusive);
    final expectedEnd = endOfLocalMonthExclusive(start);
    return start.day == 1 && period.endExclusive == expectedEnd;
  }

  /// Counts Monday–Friday days in `[startInclusive, endExclusive)`.
  static int countStandardWorkingDays(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    var count = 0;
    var cursor = startOfLocalDay(startInclusive);
    while (cursor.isBefore(endExclusive)) {
      if (cursor.weekday <= DateTime.friday) {
        count += 1;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }
}

class _PayBreakdown {
  const _PayBreakdown({
    required this.amount,
    required this.isProrated,
    required this.description,
  });

  final double amount;
  final bool isProrated;
  final String description;
}
