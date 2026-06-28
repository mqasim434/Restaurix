import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/attendance_record.dart';
import 'package:restaurix/domain/models/employee.dart';
import 'package:restaurix/domain/models/salary_calculation.dart';
import 'package:restaurix/domain/models/salary_slip.dart';
import 'package:restaurix/domain/services/salary_calculation_service.dart';
import 'package:restaurix/domain/services/salary_slip_service.dart';
import 'package:restaurix/features/salary/slips/salary_slip_preview.dart';
import 'package:flutter_test/flutter_test.dart';

Employee _employee({
  required String id,
  required String fullName,
  EmployeePayType payType = EmployeePayType.hourly,
  double? hourlyRate = 20,
  bool isActive = true,
}) {
  final now = DateTime(2024, 6, 1);
  return Employee(
    id: id,
    fullName: fullName,
    role: 'Staff',
    hireDate: now,
    payType: payType,
    hourlyRate: hourlyRate,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'device',
    version: 1,
  );
}

AttendanceRecord _record({
  required String employeeId,
  required DateTime checkIn,
  DateTime? checkOut,
}) {
  final now = DateTime(2024, 6, 1);
  return AttendanceRecord(
    id: 'rec-${checkIn.millisecondsSinceEpoch}',
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

SalarySlip _slip({
  required String employeeId,
  required double basePay,
  double totalHours = 8,
  double? deductions,
  SalarySlipStatus status = SalarySlipStatus.draft,
}) {
  final now = DateTime(2024, 7, 1);
  final netPay = computeSalaryNetPay(basePay: basePay, deductions: deductions);
  return SalarySlip(
    id: 'slip-1',
    employeeId: employeeId,
    periodStart: DateTime(2024, 6, 1),
    periodEnd: DateTime(2024, 6, 30),
    totalHours: totalHours,
    basePay: basePay,
    deductions: deductions,
    netPay: netPay,
    generatedAt: now,
    generatedByUserId: 'admin',
    status: status,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'device',
    version: 1,
  );
}

void main() {
  group('SalarySlipService', () {
    test('priorCalendarMonthPeriod resolves the month before anchor', () {
      final period = SalarySlipService.priorCalendarMonthPeriod(
        DateTime(2024, 7, 15),
      );

      expect(period.startInclusive, DateTime(2024, 6, 1));
      expect(period.endExclusive, DateTime(2024, 7, 1));
    });

    test('auto generation runs on configured day when period is missing', () {
      final check = SalarySlipService.evaluateAutoGeneration(
        generationDay: 1,
        now: DateTime(2024, 7, 1),
        priorPeriodAlreadyGenerated: false,
      );

      expect(check.shouldGenerate, isTrue);
      expect(check.period.startInclusive, DateTime(2024, 6, 1));
    });

    test('auto generation is skipped before configured day', () {
      final check = SalarySlipService.evaluateAutoGeneration(
        generationDay: 5,
        now: DateTime(2024, 7, 3),
        priorPeriodAlreadyGenerated: false,
      );

      expect(check.shouldGenerate, isFalse);
    });

    test('auto generation is idempotent when prior period already exists', () {
      final check = SalarySlipService.evaluateAutoGeneration(
        generationDay: 1,
        now: DateTime(2024, 7, 10),
        priorPeriodAlreadyGenerated: true,
      );

      expect(check.shouldGenerate, isFalse);
    });

    test('buildDraftInputs includes inactive employees with computed pay', () {
      final employees = [
        _employee(id: 'e1', fullName: 'Active Alice'),
        _employee(id: 'e2', fullName: 'Inactive Bob', isActive: false),
      ];
      final records = [
        _record(
          employeeId: 'e1',
          checkIn: DateTime(2024, 6, 3, 9),
          checkOut: DateTime(2024, 6, 3, 17),
        ),
      ];
      final period = SalaryPeriod(
        startInclusive: DateTime(2024, 6, 1),
        endExclusive: DateTime(2024, 7, 1),
      );

      final calculation = SalaryCalculationService.calculate(
        period: period,
        mode: SalaryCalculationMode.finalPayroll,
        employees: employees,
        attendanceRecords: records,
      );
      final inputs = SalarySlipService.buildDraftInputs(
        calculation: calculation,
        period: period,
      );

      expect(inputs, hasLength(2));
      expect(inputs.firstWhere((input) => input.employeeId == 'e1').basePay, 160);
      expect(inputs.firstWhere((input) => input.employeeId == 'e2').basePay, 0);
    });
  });

  group('Salary slip immutability helpers', () {
    test('computeSalaryNetPay subtracts optional deductions', () {
      expect(
        computeSalaryNetPay(basePay: 1000, deductions: 150),
        850,
      );
      expect(computeSalaryNetPay(basePay: 1000), 1000);
    });

    test('preview renders finalized lock message', () {
      final document = buildSalarySlipDocument(
        businessName: 'Restaurix Cafe',
        employee: _employee(id: 'e1', fullName: 'Alice'),
        slip: _slip(
          employeeId: 'e1',
          basePay: 160,
          status: SalarySlipStatus.finalized,
        ),
      );

      expect(
        SalarySlipPreview.renderText(document),
        contains('This slip is finalized and locked.'),
      );
    });
  });
}
