import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/pickup_company.dart';
import '../local/collections/pickup_company_isar.dart';
import '../local/mappers/delivery_mapper.dart';

class PickupCompanyRepository {
  PickupCompanyRepository(this._isar);

  final Isar _isar;

  Stream<List<PickupCompany>> watchAll() {
    return _isar.pickupCompanyIsars
        .filter()
        .deletedAtIsNull()
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(pickupCompanyFromIsar).toList());
  }

  Stream<List<PickupCompany>> watchActive() {
    return _isar.pickupCompanyIsars
        .filter()
        .deletedAtIsNull()
        .isActiveEqualTo(true)
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(pickupCompanyFromIsar).toList());
  }

  Future<PickupCompany> create({
    required String name,
    required String deviceId,
    String? logoUrl,
    bool isActive = true,
  }) async {
    final record = PickupCompanyIsar.create(
      name: name.trim(),
      deviceId: deviceId,
      logoUrl: logoUrl,
      isActive: isActive,
    );

    await _isar.writeTxn(() async {
      await _isar.pickupCompanyIsars.put(record);
    });

    return pickupCompanyFromIsar(record);
  }

  Future<PickupCompany?> update({
    required PickupCompany company,
    required String deviceId,
  }) async {
    final record = await _isar.pickupCompanyIsars
        .filter()
        .uuidEqualTo(company.id)
        .findFirst();
    if (record == null || record.isDeleted) return null;

    applyPickupCompanyToIsar(
      record: record,
      company: company,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.pickupCompanyIsars.put(record);
    });

    return pickupCompanyFromIsar(record);
  }

  Future<PickupCompany?> toggleActive({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.pickupCompanyIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;

    record
      ..isActive = !record.isActive
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.pickupCompanyIsars.put(record);
    });

    return pickupCompanyFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.pickupCompanyIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.pickupCompanyIsars.put(record);
    });

    return true;
  }
}
