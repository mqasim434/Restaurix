import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/attendance_record.dart';
import 'package:restaurix/domain/models/employee.dart';
import 'package:restaurix/domain/models/salary_calculation.dart';
import 'package:restaurix/domain/services/salary_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

Employee _employee({
  required String id,
  required String fullName,
  EmployeePayType payType = EmployeePayType.hourly,
  double? hourlyRate = 20,
  double? monthlySalaryBase,
}) {
  final now = DateTime(2024, 6, 1);
  return Employee(
    id: id,
    fullName: fullName,
    role: 'Staff',
    hireDate: now,
    payType: payType,
    hourlyRate: hourlyRate,
    monthlySalaryBase: monthlySalaryBase,
    isActive: true,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'device',
    version: 1,
  );
}

AttendanceRecord _record({
  required String id,
  required String employeeId,
  required DateTime checkIn,
  DateTime? checkOut,
}) {
  final now = DateTime(2024, 6, 1);
  return AttendanceRecord(
    id: id,
    employeeId: employeeId,
    checkInTime: checkIn,
    checkOutTime: checkOut,
    source: AttendanceSource.manual,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'device',
    version: 1,
  );
}

void main() {
  group('SalaryCalculationService', () {
    final period = SalaryPeriod(
      startInclusive: DateTime(2024, 6, 1),
      endExclusive: DateTime(2024, 6, 30, 23, 59, 59),
    );

    test('hourly employee earns rate times closed shift hours', () {
      final employee = _employee(id: 'e1', fullName: 'Alice');
      final records = [
        _record(
          id: 'r1',
          employeeId: 'e1',
          checkIn: DateTime(2024, 6, 3, 9),
          checkOut: DateTime(2024, 6, 3, 17),
        ),
      ];

      final result = SalaryCalculationService.calculate(
        period: period,
        mode: SalaryCalculationMode.finalPayroll,
        employees: [employee],
        attendanceRecords: records,
      );

      expect(result.employees.single.totalHours, 8);
      expect(result.employees.single.grossPay, 160);
      expect(result.employees.single.closedShiftCount, 1);
      expect(result.employees.single.openShiftCountIncluded, 0);
    });

    test('final payroll excludes open shifts', () {
      final employee = _employee(id: 'e1', fullName: 'Alice');
      final records = [
        _record(
          id: 'r1',
          employeeId: 'e1',
          checkIn: DateTime(2024, 6, 3, 9),
        ),
      ];

      final result = SalaryCalculationService.calculate(
        period: period,
        mode: SalaryCalculationMode.finalPayroll,
        employees: [employee],
        attendanceRecords: records,
      );

      expect(result.employees.single.totalHours, 0);
      expect(result.employees.single.grossPay, 0);
      expect(result.employees.single.closedShiftCount, 0);
      expect(result.employees.single.openShiftCountIncluded, 0);
    });

    test('live estimate includes open shifts up to asOf', () {
      final employee = _employee(id: 'e1', fullName: 'Alice');
      final records = [
        _record(
          id: 'r1',
          employeeId: 'e1',
          checkIn: DateTime(2024, 6, 3, 9),
        ),
      ];
      final asOf = DateTime(2024, 6, 3, 13);

      final result = SalaryCalculationService.calculate(
        period: period,
        mode: SalaryCalculationMode.liveEstimate,
        employees: [employee],
        attendanceRecords: records,
        asOf: asOf,
      );

      expect(result.employees.single.totalHours, 4);
      expect(result.employees.single.grossPay, 80);
      expect(result.employees.single.openShiftCountIncluded, 1);
    });

    test('overnight shift duration spans midnight', () {
      final employee = _employee(id: 'e1', fullName: 'Alice');
      final records = [
        _record(
          id: 'r1',
          employeeId: 'e1',
          checkIn: DateTime(2024, 6, 3, 22),
          checkOut: DateTime(2024, 6, 4, 6),
        ),
      ];

      final result = SalaryCalculationService.calculate(
        period: period,
        mode: SalaryCalculationMode.finalPayroll,
        employees: [employee],
        attendanceRecords: records,
      );

      expect(result.employees.single.totalHours, 8);
      expect(result.employees.single.grossPay, 160);
    });

    test('monthly employee receives full salary for full calendar month', () {
      final employee = _employee(
        id: 'e1',
        fullName: 'Bob',
        payType: EmployeePayType.monthly,
        hourlyRate: null,
        monthlySalaryBase: 3000,
      );
      final fullMonth = SalaryPeriod(
        startInclusive: DateTime(2024, 6, 1),
        endExclusive: DateTime(2024, 7, 1),
      );

      final result = SalaryCalculationService.calculate(
        period: fullMonth,
        mode: SalaryCalculationMode.finalPayroll,
        employees: [employee],
        attendanceRecords: const [],
      );

      expect(result.employees.single.grossPay, 3000);
      expect(result.employees.single.isProratedMonthly, isFalse);
      expect(result.employees.single.totalHours, 0);
    });

    test('monthly employee is prorated for partial month ranges', () {
      final employee = _employee(
        id: 'e1',
        fullName: 'Bob',
        payType: EmployeePayType.monthly,
        hourlyRate: null,
        monthlySalaryBase: 3000,
      );
      final partialMonth = SalaryPeriod(
        startInclusive: DateTime(2024, 6, 3),
        endExclusive: DateTime(2024, 6, 8),
      );
      final workingDaysInMonth = SalaryCalculationService.countStandardWorkingDays(
        DateTime(2024, 6, 1),
        DateTime(2024, 7, 1),
      );
      final workingDaysInPeriod = SalaryCalculationService.countStandardWorkingDays(
        partialMonth.startInclusive,
        partialMonth.endExclusive,
      );

      final result = SalaryCalculationService.calculate(
        period: partialMonth,
        mode: SalaryCalculationMode.finalPayroll,
        employees: [employee],
        attendanceRecords: const [],
      );

      expect(workingDaysInPeriod, 5);
      expect(result.employees.single.isProratedMonthly, isTrue);
      expect(
        result.employees.single.grossPay,
        closeTo(3000 * (workingDaysInPeriod / workingDaysInMonth), 0.01),
      );
    });

    test('zero attendance records yields zero pay without error', () {
      final employee = _employee(id: 'e1', fullName: 'Alice');

      final result = SalaryCalculationService.calculate(
        period: period,
        mode: SalaryCalculationMode.finalPayroll,
        employees: [employee],
        attendanceRecords: const [],
      );

      expect(result.employees.single.totalHours, 0);
      expect(result.employees.single.grossPay, 0);
      expect(result.totalGrossPay, 0);
    });

    test('records outside the period are ignored', () {
      final employee = _employee(id: 'e1', fullName: 'Alice');
      final records = [
        _record(
          id: 'r1',
          employeeId: 'e1',
          checkIn: DateTime(2024, 5, 31, 9),
          checkOut: DateTime(2024, 5, 31, 17),
        ),
      ];

      final result = SalaryCalculationService.calculate(
        period: period,
        mode: SalaryCalculationMode.finalPayroll,
        employees: [employee],
        attendanceRecords: records,
      );

      expect(result.employees.single.totalHours, 0);
      expect(result.employees.single.grossPay, 0);
    });

    test('calculates each employee independently', () {
      final alice = _employee(id: 'e1', fullName: 'Alice', hourlyRate: 10);
      final bob = _employee(id: 'e2', fullName: 'Bob', hourlyRate: 30);
      final records = [
        _record(
          id: 'r1',
          employeeId: 'e1',
          checkIn: DateTime(2024, 6, 3, 9),
          checkOut: DateTime(2024, 6, 3, 11),
        ),
        _record(
          id: 'r2',
          employeeId: 'e2',
          checkIn: DateTime(2024, 6, 3, 9),
          checkOut: DateTime(2024, 6, 3, 12),
        ),
      ];

      final result = SalaryCalculationService.calculate(
        period: period,
        mode: SalaryCalculationMode.finalPayroll,
        employees: [bob, alice],
        attendanceRecords: records,
      );

      expect(result.employees.map((row) => row.employee.fullName), [
        'Alice',
        'Bob',
      ]);
      expect(result.employees[0].grossPay, 20);
      expect(result.employees[1].grossPay, 90);
      expect(result.totalGrossPay, 110);
    });
  });
}
