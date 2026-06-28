import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_range_utils.dart';
import '../../../../data/repositories/salary_calculation_repository.dart';
import '../../../../domain/models/salary_calculation.dart';
import '../../../attendance/providers/attendance_providers.dart';
import '../../../employees/providers/employee_providers.dart';
import '../../../reports/providers/reports_providers.dart';

final salaryCalculationRepositoryProvider =
    Provider<SalaryCalculationRepository>((ref) {
  return SalaryCalculationRepository(
    employeeRepository: ref.watch(employeeRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
  );
});

class SalaryFilterState {
  const SalaryFilterState({
    this.preset = SalesDateRangePreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.mode = SalaryCalculationMode.finalPayroll,
  });

  final SalesDateRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final SalaryCalculationMode mode;

  SalesDateRange resolve({DateTime? now}) {
    return resolveSalesDateRange(
      preset: preset,
      customStart: customStart,
      customEnd: customEnd,
      now: now,
    );
  }

  ReportsFilterState toDateRangeFilter() {
    return ReportsFilterState(
      preset: preset,
      customStart: customStart,
      customEnd: customEnd,
    );
  }

  SalaryFilterState copyWith({
    SalesDateRangePreset? preset,
    DateTime? customStart,
    DateTime? customEnd,
    SalaryCalculationMode? mode,
    bool clearCustomDates = false,
  }) {
    return SalaryFilterState(
      preset: preset ?? this.preset,
      customStart: clearCustomDates ? null : (customStart ?? this.customStart),
      customEnd: clearCustomDates ? null : (customEnd ?? this.customEnd),
      mode: mode ?? this.mode,
    );
  }
}

final salaryFilterProvider =
    StateProvider<SalaryFilterState>((ref) => const SalaryFilterState());

final salaryCalculationProvider =
    FutureProvider.autoDispose<SalaryCalculationResult>((ref) async {
  final filter = ref.watch(salaryFilterProvider);
  final range = filter.resolve();

  return ref.watch(salaryCalculationRepositoryProvider).calculate(
        range: range,
        mode: filter.mode,
      );
});
