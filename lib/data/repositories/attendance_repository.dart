import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/employee.dart';
import '../../domain/services/attendance_service.dart';
import '../local/collections/attendance_record_isar.dart';
import '../local/mappers/attendance_mapper.dart';
import 'employee_repository.dart';

class AttendanceRepository {
  AttendanceRepository(this._isar);

  final Isar _isar;

  Future<List<AttendanceRecord>> findInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    String? employeeId,
  }) async {
    final records = await _isar.attendanceRecordIsars
        .filter()
        .deletedAtIsNull()
        .checkInTimeGreaterThan(startInclusive, include: true)
        .checkInTimeLessThan(endExclusive, include: false)
        .findAll();

    final mapped = records.map(attendanceRecordFromIsar).toList();
    if (employeeId == null) return mapped;
    return mapped.where((record) => record.employeeId == employeeId).toList();
  }

  Stream<List<AttendanceRecord>> watchAll() {
    return _isar.attendanceRecordIsars
        .filter()
        .deletedAtIsNull()
        .sortByCheckInTimeDesc()
        .watch(fireImmediately: true)
        .map((records) => records.map(attendanceRecordFromIsar).toList());
  }

  Future<AttendanceRecord?> findOpenForEmployee(String employeeId) async {
    final records = await _isar.attendanceRecordIsars
        .filter()
        .deletedAtIsNull()
        .employeeIdEqualTo(employeeId)
        .findAll();

    for (final record in records) {
      if (record.isOpen) {
        return attendanceRecordFromIsar(record);
      }
    }
    return null;
  }

  Future<AttendanceRecord> checkIn({
    required String employeeId,
    required AttendanceSource source,
    required String deviceId,
    required DateTime checkInTime,
    String? createdByUserId,
    String? notes,
  }) async {
    final record = AttendanceRecordIsar.create(
      employeeId: employeeId,
      checkInTime: checkInTime,
      source: source,
      deviceId: deviceId,
      createdByUserId: createdByUserId,
      notes: notes,
    );

    await _isar.writeTxn(() async {
      await _isar.attendanceRecordIsars.put(record);
    });

    return attendanceRecordFromIsar(record);
  }

  Future<AttendanceRecord?> checkOut({
    required String recordId,
    required DateTime checkOutTime,
    required String deviceId,
    String? notes,
  }) async {
    final record = await _isar.attendanceRecordIsars
        .filter()
        .uuidEqualTo(recordId)
        .findFirst();
    if (record == null || record.isDeleted || !record.isOpen) return null;

    record
      ..checkOutTime = checkOutTime
      ..notes = notes ?? record.notes
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.attendanceRecordIsars.put(record);
    });

    return attendanceRecordFromIsar(record);
  }

  Future<AttendanceRecord?> updateManualRecord({
    required AttendanceRecord attendanceRecord,
    required String deviceId,
  }) async {
    final record = await _isar.attendanceRecordIsars
        .filter()
        .uuidEqualTo(attendanceRecord.id)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    applyAttendanceRecordToIsar(
      record: record,
      attendanceRecord: attendanceRecord,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.attendanceRecordIsars.put(record);
    });

    return attendanceRecordFromIsar(record);
  }
}

class AttendanceCoordinator {
  AttendanceCoordinator({
    required AttendanceRepository attendanceRepository,
    required EmployeeRepository employeeRepository,
  })  : _attendanceRepository = attendanceRepository,
        _employeeRepository = employeeRepository;

  final AttendanceRepository _attendanceRepository;
  final EmployeeRepository _employeeRepository;

  Future<AttendanceOperationResult> handleFingerprintScan({
    required String fingerprintEnrollmentId,
    required String deviceId,
    DateTime? now,
  }) async {
    final employee = await _employeeRepository
        .findByFingerprintEnrollmentId(fingerprintEnrollmentId);
    if (employee == null) {
      return (
        success: null,
        failure: const AttendanceFailure(
          reason: AttendanceFailureReason.unrecognized,
          message: 'No enrolled employee matched this fingerprint',
        ),
      );
    }

    if (!employee.isActive) {
      return (
        success: null,
        failure: AttendanceFailure(
          reason: AttendanceFailureReason.inactiveEmployee,
          message: '${employee.fullName} is inactive and cannot clock in',
        ),
      );
    }

    return _toggleShift(
      employee: employee,
      source: AttendanceSource.fingerprint,
      deviceId: deviceId,
      createdByUserId: null,
      now: now ?? DateTime.now(),
    );
  }

  Future<AttendanceOperationResult> manualCheckIn({
    required String employeeId,
    required String createdByUserId,
    required String deviceId,
    required DateTime checkInTime,
    String? notes,
  }) async {
    final employee = await _employeeRepository.findById(employeeId);
    if (employee == null) {
      return (
        success: null,
        failure: const AttendanceFailure(
          reason: AttendanceFailureReason.unrecognized,
          message: 'Employee not found',
        ),
      );
    }

    final open = await _attendanceRepository.findOpenForEmployee(employeeId);
    if (open != null) {
      return (
        success: null,
        failure: AttendanceFailure(
          reason: AttendanceFailureReason.inactiveEmployee,
          message: '${employee.fullName} already has an open shift',
        ),
      );
    }

    final record = await _attendanceRepository.checkIn(
      employeeId: employeeId,
      source: AttendanceSource.manual,
      deviceId: deviceId,
      checkInTime: checkInTime,
      createdByUserId: createdByUserId,
      notes: notes,
    );

    return (
      success: AttendanceSuccess(
        action: AttendanceScanAction.checkIn,
        employee: employee,
        record: record,
      ),
      failure: null,
    );
  }

  Future<AttendanceOperationResult> manualCheckOut({
    required String recordId,
    required String createdByUserId,
    required String deviceId,
    required DateTime checkOutTime,
    String? notes,
  }) async {
    final updated = await _attendanceRepository.checkOut(
      recordId: recordId,
      checkOutTime: checkOutTime,
      deviceId: deviceId,
      notes: notes,
    );
    if (updated == null) {
      return (
        success: null,
        failure: const AttendanceFailure(
          reason: AttendanceFailureReason.unrecognized,
          message: 'Open attendance record not found',
        ),
      );
    }

    final employee = await _employeeRepository.findById(updated.employeeId);
    if (employee == null) {
      return (
        success: null,
        failure: const AttendanceFailure(
          reason: AttendanceFailureReason.unrecognized,
          message: 'Employee not found for attendance record',
        ),
      );
    }

    return (
      success: AttendanceSuccess(
        action: AttendanceScanAction.checkOut,
        employee: employee,
        record: updated.copyWith(createdByUserId: createdByUserId),
      ),
      failure: null,
    );
  }

  Future<Employee?> enrollFingerprint({
    required String employeeId,
    required String fingerprintEnrollmentId,
    required String deviceId,
  }) {
    return _employeeRepository.setFingerprintEnrollment(
      employeeId: employeeId,
      fingerprintEnrollmentId: fingerprintEnrollmentId,
      deviceId: deviceId,
    );
  }

  Future<AttendanceOperationResult> _toggleShift({
    required Employee employee,
    required AttendanceSource source,
    required String deviceId,
    required String? createdByUserId,
    required DateTime now,
    String? notes,
  }) async {
    final open = await _attendanceRepository.findOpenForEmployee(employee.id);
    final action = AttendanceRules.resolveScanAction(hasOpenShift: open != null);

    if (action == AttendanceScanAction.checkOut && open != null) {
      final record = await _attendanceRepository.checkOut(
        recordId: open.id,
        checkOutTime: now,
        deviceId: deviceId,
        notes: notes,
      );
      return (
        success: AttendanceSuccess(
          action: action,
          employee: employee,
          record: record!,
        ),
        failure: null,
      );
    }

    final record = await _attendanceRepository.checkIn(
      employeeId: employee.id,
      source: source,
      deviceId: deviceId,
      checkInTime: now,
      createdByUserId: createdByUserId,
      notes: notes,
    );

    return (
      success: AttendanceSuccess(
        action: AttendanceScanAction.checkIn,
        employee: employee,
        record: record,
      ),
      failure: null,
    );
  }
}
