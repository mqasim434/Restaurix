import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/employee.dart';
import '../local/collections/employee_isar.dart';
import '../local/mappers/employee_mapper.dart';

class EmployeeRepository {
  EmployeeRepository(this._isar);

  final Isar _isar;

  Stream<List<Employee>> watchAll() {
    return _isar.employeeIsars
        .filter()
        .deletedAtIsNull()
        .sortByFullName()
        .watch(fireImmediately: true)
        .map((records) => records.map(employeeFromIsar).toList());
  }

  Future<List<Employee>> findAll() async {
    final records = await _isar.employeeIsars
        .filter()
        .deletedAtIsNull()
        .sortByFullName()
        .findAll();
    return records.map(employeeFromIsar).toList();
  }

  Stream<List<Employee>> watchActive() {
    return _isar.employeeIsars
        .filter()
        .deletedAtIsNull()
        .isActiveEqualTo(true)
        .sortByFullName()
        .watch(fireImmediately: true)
        .map((records) => records.map(employeeFromIsar).toList());
  }

  Future<Employee?> findByFingerprintEnrollmentId(
    String fingerprintEnrollmentId,
  ) async {
    final record = await _isar.employeeIsars
        .filter()
        .deletedAtIsNull()
        .fingerprintEnrollmentIdEqualTo(fingerprintEnrollmentId)
        .findFirst();
    if (record == null || record.isDeleted) return null;
    return employeeFromIsar(record);
  }

  Future<Employee?> setFingerprintEnrollment({
    required String employeeId,
    required String fingerprintEnrollmentId,
    required String deviceId,
  }) async {
    final record =
        await _isar.employeeIsars.filter().uuidEqualTo(employeeId).findFirst();
    if (record == null || record.isDeleted) return null;

    record
      ..fingerprintEnrollmentId = fingerprintEnrollmentId
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.employeeIsars.put(record);
    });

    return employeeFromIsar(record);
  }

  Future<Employee?> findById(String id) async {
    final record =
        await _isar.employeeIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return employeeFromIsar(record);
  }

  Future<Employee> create({
    required String fullName,
    required String role,
    required DateTime hireDate,
    required EmployeePayType payType,
    required String deviceId,
    String? phone,
    double? hourlyRate,
    double? monthlySalaryBase,
    String? fingerprintEnrollmentId,
    bool isActive = true,
  }) async {
    final record = EmployeeIsar.create(
      fullName: fullName.trim(),
      role: role.trim(),
      hireDate: hireDate,
      payType: payType,
      deviceId: deviceId,
      phone: phone?.trim(),
      hourlyRate: payType == EmployeePayType.hourly ? hourlyRate : null,
      monthlySalaryBase:
          payType == EmployeePayType.monthly ? monthlySalaryBase : null,
      fingerprintEnrollmentId: fingerprintEnrollmentId?.trim(),
      isActive: isActive,
    );

    await _isar.writeTxn(() async {
      await _isar.employeeIsars.put(record);
    });

    return employeeFromIsar(record);
  }

  Future<Employee?> update({
    required Employee employee,
    required String deviceId,
  }) async {
    final record =
        await _isar.employeeIsars.filter().uuidEqualTo(employee.id).findFirst();
    if (record == null || record.isDeleted) return null;

    applyEmployeeToIsar(
      record: record,
      employee: employee,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.employeeIsars.put(record);
    });

    return employeeFromIsar(record);
  }

  Future<Employee?> setActive({
    required String id,
    required bool isActive,
    required String deviceId,
  }) async {
    final record = await _isar.employeeIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;

    record
      ..isActive = isActive
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.employeeIsars.put(record);
    });

    return employeeFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record = await _isar.employeeIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.employeeIsars.put(record);
    });

    return true;
  }
}
