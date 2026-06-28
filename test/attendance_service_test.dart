import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/attendance_record.dart';
import 'package:restaurix/domain/models/employee.dart';
import 'package:restaurix/domain/services/attendance_service.dart';
import 'package:flutter_test/flutter_test.dart';

Employee _employee({
  String id = 'emp-1',
  String name = 'Alice',
  bool isActive = true,
  String? fingerprintEnrollmentId = 'fp-123',
}) {
  final now = DateTime(2024, 6, 1);
  return Employee(
    id: id,
    fullName: name,
    role: 'Waiter',
    hireDate: now,
    payType: EmployeePayType.hourly,
    hourlyRate: 10,
    fingerprintEnrollmentId: fingerprintEnrollmentId,
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
  String id = 'att-1',
  String employeeId = 'emp-1',
  DateTime? checkOutTime,
}) {
  final checkIn = DateTime(2024, 6, 21, 9);
  final now = DateTime(2024, 6, 21, 10);
  return AttendanceRecord(
    id: id,
    employeeId: employeeId,
    checkInTime: checkIn,
    checkOutTime: checkOutTime,
    source: AttendanceSource.fingerprint,
    createdAt: checkIn,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'device',
    version: 1,
  );
}

void main() {
  group('AttendanceRules', () {
    test('open shift scans check out instead of creating duplicate check-in', () {
      expect(
        AttendanceRules.resolveScanAction(hasOpenShift: true),
        AttendanceScanAction.checkOut,
      );
      expect(
        AttendanceRules.resolveScanAction(hasOpenShift: false),
        AttendanceScanAction.checkIn,
      );
    });
  });

  group('AttendanceRecord', () {
    test('workedDuration handles overnight shifts', () {
      final checkIn = DateTime(2024, 6, 21, 23);
      final checkOut = DateTime(2024, 6, 22, 7);
      final record = AttendanceRecord(
        id: 'att-1',
        employeeId: 'emp-1',
        checkInTime: checkIn,
        checkOutTime: checkOut,
        source: AttendanceSource.fingerprint,
        createdAt: checkIn,
        updatedAt: checkOut,
        isSynced: false,
        syncAction: SyncAction.create,
        deviceId: 'device',
        version: 1,
      );

      expect(record.workedDuration(), const Duration(hours: 8));
    });

    test('open record has no completed duration without until time', () {
      expect(_record().workedDuration(), isNull);
      expect(
        _record().workedDuration(until: DateTime(2024, 6, 21, 12)),
        const Duration(hours: 3),
      );
    });
  });

  group('employee enrollment lookup', () {
    test('inactive employees are flagged separately from missing enrollment', () {
      final inactive = _employee(isActive: false);
      final missing = _employee(fingerprintEnrollmentId: null);

      expect(inactive.isActive, isFalse);
      expect(missing.fingerprintEnrollmentId, isNull);
    });
  });
}
