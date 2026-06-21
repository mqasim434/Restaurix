import 'package:isar/isar.dart';

import 'collections/debug_ping_isar.dart';

class DebugPingRepository {
  DebugPingRepository(this._isar);

  final Isar _isar;

  Stream<List<DebugPingIsar>> watchAll() {
    return _isar.debugPingIsars
        .filter()
        .deletedAtIsNull()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<DebugPingIsar> create({
    required String message,
    required String deviceId,
  }) async {
    final record = DebugPingIsar.create(message: message, deviceId: deviceId);
    await _isar.writeTxn(() async {
      await _isar.debugPingIsars.put(record);
    });
    return record;
  }

  Future<DebugPingIsar?> updateMessage({
    required String uuid,
    required String message,
    required String deviceId,
  }) async {
    final record = await _isar.debugPingIsars.filter().uuidEqualTo(uuid).findFirst();
    if (record == null || record.isDeleted) return null;

    record
      ..message = message
      ..markUpdated(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.debugPingIsars.put(record);
    });
    return record;
  }

  Future<bool> softDelete({
    required String uuid,
    required String deviceId,
  }) async {
    final record = await _isar.debugPingIsars.filter().uuidEqualTo(uuid).findFirst();
    if (record == null || record.isDeleted) return false;

    record.markDeleted(deviceId: deviceId);

    await _isar.writeTxn(() async {
      await _isar.debugPingIsars.put(record);
    });
    return true;
  }
}
