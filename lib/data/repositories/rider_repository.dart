import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/rider.dart';
import '../local/collections/rider_isar.dart';
import '../local/mappers/delivery_mapper.dart';

class RiderRepository {
  RiderRepository(this._isar);

  final Isar _isar;

  Stream<List<Rider>> watchAll() {
    return _isar.riderIsars
        .filter()
        .deletedAtIsNull()
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(riderFromIsar).toList());
  }

  Stream<List<Rider>> watchActive() {
    return _isar.riderIsars
        .filter()
        .deletedAtIsNull()
        .isActiveEqualTo(true)
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(riderFromIsar).toList());
  }

  Future<Rider> create({
    required String name,
    required String deviceId,
    String? phone,
    bool isActive = true,
  }) async {
    final record = RiderIsar.create(
      name: name.trim(),
      deviceId: deviceId,
      phone: phone?.trim(),
      isActive: isActive,
    );

    await _isar.writeTxn(() async {
      await _isar.riderIsars.put(record);
    });

    return riderFromIsar(record);
  }

  Future<Rider?> update({
    required Rider rider,
    required String deviceId,
  }) async {
    final record =
        await _isar.riderIsars.filter().uuidEqualTo(rider.id).findFirst();
    if (record == null || record.isDeleted) return null;

    applyRiderToIsar(
      record: record,
      rider: rider,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.riderIsars.put(record);
    });

    return riderFromIsar(record);
  }

  Future<Rider?> toggleActive({
    required String id,
    required String deviceId,
  }) async {
    final record = await _isar.riderIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;

    record
      ..isActive = !record.isActive
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.riderIsars.put(record);
    });

    return riderFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record = await _isar.riderIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.riderIsars.put(record);
    });

    return true;
  }
}
