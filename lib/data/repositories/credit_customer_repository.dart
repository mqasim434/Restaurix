import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/credit_customer.dart';
import '../local/collections/credit_customer_isar.dart';
import '../local/mappers/credit_customer_mapper.dart';

class CreditCustomerRepository {
  CreditCustomerRepository(this._isar);

  final Isar _isar;

  Stream<List<CreditCustomer>> watchAll() {
    return _isar.creditCustomerIsars
        .filter()
        .deletedAtIsNull()
        .sortByFullName()
        .watch(fireImmediately: true)
        .map((records) => records.map(creditCustomerFromIsar).toList());
  }

  Stream<List<CreditCustomer>> watchActive() {
    return _isar.creditCustomerIsars
        .filter()
        .deletedAtIsNull()
        .isActiveEqualTo(true)
        .sortByFullName()
        .watch(fireImmediately: true)
        .map((records) => records.map(creditCustomerFromIsar).toList());
  }

  Future<List<CreditCustomer>> findAllActive() async {
    final records = await _isar.creditCustomerIsars
        .filter()
        .deletedAtIsNull()
        .isActiveEqualTo(true)
        .sortByFullName()
        .findAll();
    return records.map(creditCustomerFromIsar).toList();
  }

  Future<CreditCustomer?> findById(String id) async {
    final record =
        await _isar.creditCustomerIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return creditCustomerFromIsar(record);
  }

  Future<CreditCustomer> create({
    required String fullName,
    required String deviceId,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postcode,
    String? notes,
    double? creditLimit,
    bool isActive = true,
  }) async {
    final record = CreditCustomerIsar.create(
      fullName: fullName.trim(),
      deviceId: deviceId,
      phone: phone?.trim(),
      addressLine1: addressLine1?.trim(),
      addressLine2: addressLine2?.trim(),
      city: city?.trim(),
      postcode: postcode?.trim(),
      notes: notes?.trim(),
      creditLimit: creditLimit,
      isActive: isActive,
    );

    await _isar.writeTxn(() async {
      await _isar.creditCustomerIsars.put(record);
    });

    return creditCustomerFromIsar(record);
  }

  Future<CreditCustomer?> update({
    required CreditCustomer customer,
    required String deviceId,
  }) async {
    final record = await _isar.creditCustomerIsars
        .filter()
        .uuidEqualTo(customer.id)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    applyCreditCustomerToIsar(
      record: record,
      customer: customer,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.creditCustomerIsars.put(record);
    });

    return creditCustomerFromIsar(record);
  }

  Future<CreditCustomer?> setActive({
    required String id,
    required bool isActive,
    required String deviceId,
  }) async {
    final record =
        await _isar.creditCustomerIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;

    record
      ..isActive = isActive
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.creditCustomerIsars.put(record);
    });

    return creditCustomerFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.creditCustomerIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.creditCustomerIsars.put(record);
    });

    return true;
  }

}
