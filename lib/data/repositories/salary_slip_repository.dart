import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../core/utils/date_range_utils.dart';
import '../../domain/models/salary_slip.dart';
import '../../domain/services/salary_slip_service.dart';
import '../local/collections/salary_slip_isar.dart';
import '../local/mappers/salary_slip_mapper.dart';

class SalarySlipRepository {
  SalarySlipRepository(this._isar);

  final Isar _isar;

  Stream<List<SalarySlip>> watchAll() {
    return _isar.salarySlipIsars
        .filter()
        .deletedAtIsNull()
        .sortByPeriodStartDesc()
        .watch(fireImmediately: true)
        .map((records) => records.map(salarySlipFromIsar).toList());
  }

  Future<SalarySlip?> findById(String id) async {
    final record =
        await _isar.salarySlipIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return salarySlipFromIsar(record);
  }

  Future<SalarySlip?> findForEmployeePeriod({
    required String employeeId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final normalizedStart = localDateBucket(periodStart);
    final normalizedEnd = localDateBucket(periodEnd);

    final records = await _isar.salarySlipIsars
        .filter()
        .deletedAtIsNull()
        .employeeIdEqualTo(employeeId)
        .periodStartEqualTo(normalizedStart)
        .periodEndEqualTo(normalizedEnd)
        .findAll();

    if (records.isEmpty) return null;
    return salarySlipFromIsar(records.first);
  }

  Future<bool> hasSlipsForPeriod({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final normalizedStart = localDateBucket(periodStart);
    final normalizedEnd = localDateBucket(periodEnd);

    final count = await _isar.salarySlipIsars
        .filter()
        .deletedAtIsNull()
        .periodStartEqualTo(normalizedStart)
        .periodEndEqualTo(normalizedEnd)
        .count();
    return count > 0;
  }

  Future<SalarySlip> createDraft({
    required SalarySlipDraftInput input,
    required String generatedByUserId,
    required String deviceId,
    DateTime? generatedAt,
  }) async {
    final record = SalarySlipIsar.create(
      employeeId: input.employeeId,
      periodStart: localDateBucket(input.periodStart),
      periodEnd: localDateBucket(input.periodEnd),
      totalHours: input.totalHours,
      basePay: input.basePay,
      deductions: input.deductions,
      netPay: input.netPay,
      generatedByUserId: generatedByUserId,
      deviceId: deviceId,
      generatedAt: generatedAt,
    );

    await _isar.writeTxn(() async {
      await _isar.salarySlipIsars.put(record);
    });

    return salarySlipFromIsar(record);
  }

  Future<SalarySlip?> updateDraftDeductions({
    required String slipId,
    required double? deductions,
    required String deviceId,
  }) async {
    final record =
        await _isar.salarySlipIsars.filter().uuidEqualTo(slipId).findFirst();
    if (record == null || record.isDeleted) return null;
    if (record.statusEnum == SalarySlipStatus.finalized) return null;

    final netPay = computeSalaryNetPay(
      basePay: record.basePay,
      deductions: deductions,
    );

    record
      ..deductions = deductions
      ..netPay = netPay
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.salarySlipIsars.put(record);
    });

    return salarySlipFromIsar(record);
  }

  Future<SalarySlip?> finalize({
    required String slipId,
    required String deviceId,
  }) async {
    final record =
        await _isar.salarySlipIsars.filter().uuidEqualTo(slipId).findFirst();
    if (record == null || record.isDeleted) return null;
    if (record.statusEnum == SalarySlipStatus.finalized) {
      return salarySlipFromIsar(record);
    }

    record
      ..status = SalarySlipStatus.finalized.name
      ..markUpdated(deviceId: deviceId, action: SyncAction.update);

    await _isar.writeTxn(() async {
      await _isar.salarySlipIsars.put(record);
    });

    return salarySlipFromIsar(record);
  }
}
