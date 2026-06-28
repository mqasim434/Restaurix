import '../../core/utils/date_range_utils.dart';
import '../../domain/models/salary_calculation.dart';
import '../../domain/services/salary_calculation_service.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/employee_repository.dart';

class SalaryCalculationRepository {
  SalaryCalculationRepository({
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
  })  : _employeeRepository = employeeRepository,
        _attendanceRepository = attendanceRepository;

  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;

  Future<SalaryCalculationResult> calculate({
    required SalesDateRange range,
    required SalaryCalculationMode mode,
    DateTime? asOf,
  }) async {
    final period = SalaryPeriod(
      startInclusive: range.startInclusive,
      endExclusive: range.endExclusive,
    );

    final employees = await _employeeRepository.findAll();
    final attendanceRecords = await _attendanceRepository.findInRange(
      startInclusive: period.startInclusive,
      endExclusive: period.endExclusive,
    );

    return SalaryCalculationService.calculate(
      period: period,
      mode: mode,
      employees: employees,
      attendanceRecords: attendanceRecords,
      asOf: asOf,
    );
  }
}
