import 'package:isar/isar.dart';

import '../../core/sync/sync_action.dart';
import '../../domain/models/hall.dart';
import '../local/collections/hall_isar.dart';
import '../local/collections/restaurant_table_isar.dart';
import '../local/mappers/hall_mapper.dart';

class HallRepository {
  HallRepository(this._isar);

  final Isar _isar;

  Stream<List<Hall>> watchAll() {
    return _isar.hallIsars
        .filter()
        .deletedAtIsNull()
        .sortBySortOrder()
        .watch(fireImmediately: true)
        .map((records) => records.map(hallFromIsar).toList());
  }

  Future<Hall?> findById(String id) async {
    final record = await _isar.hallIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return null;
    return hallFromIsar(record);
  }

  Future<int> countTablesInHall(String hallId) async {
    return _isar.restaurantTableIsars
        .filter()
        .deletedAtIsNull()
        .hallIdEqualTo(hallId)
        .count();
  }

  Future<Hall> create({
    required String name,
    required String deviceId,
  }) async {
    final sortOrder = await _nextSortOrder();
    final record = HallIsar.create(
      name: name.trim(),
      deviceId: deviceId,
      sortOrder: sortOrder,
    );

    await _isar.writeTxn(() async {
      await _isar.hallIsars.put(record);
    });

    return hallFromIsar(record);
  }

  Future<Hall?> update({
    required Hall hall,
    required String deviceId,
  }) async {
    final record =
        await _isar.hallIsars.filter().uuidEqualTo(hall.id).findFirst();
    if (record == null || record.isDeleted) return null;

    applyHallToIsar(
      record: record,
      hall: hall,
      deviceId: deviceId,
      action: SyncAction.update,
    );

    await _isar.writeTxn(() async {
      await _isar.hallIsars.put(record);
    });

    return hallFromIsar(record);
  }

  Future<bool> softDelete({
    required String id,
    required String deviceId,
  }) async {
    final record =
        await _isar.hallIsars.filter().uuidEqualTo(id).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.hallIsars.put(record);
    });

    return true;
  }

  Future<void> reorder({
    required List<String> idsInOrder,
    required String deviceId,
  }) async {
    await _isar.writeTxn(() async {
      for (var index = 0; index < idsInOrder.length; index++) {
        final record = await _isar.hallIsars
            .filter()
            .uuidEqualTo(idsInOrder[index])
            .findFirst();
        if (record == null || record.isDeleted) continue;

        record
          ..sortOrder = index
          ..markUpdated(deviceId: deviceId);

        await _isar.hallIsars.put(record);
      }
    });
  }

  Future<int> _nextSortOrder() async {
    final records = await _isar.hallIsars
        .filter()
        .deletedAtIsNull()
        .sortBySortOrderDesc()
        .findAll();
    if (records.isEmpty) return 0;
    return records.first.sortOrder + 1;
  }
}

class HallInUseException implements Exception {
  HallInUseException(this.tableCount);

  final int tableCount;

  @override
  String toString() =>
      'Cannot delete — $tableCount table${tableCount == 1 ? '' : 's'} '
      'in this hall';
}
