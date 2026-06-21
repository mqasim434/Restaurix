import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'debug_ping_isar.g.dart';

/// Throwaway demo collection proving Isar CRUD — removed in Module 5.
///
/// Standard sync-field pattern for all future collections:
/// - `isarId` — internal Isar auto-increment key
/// - `uuid` — universal string id ([SyncableEntity.id])
/// - `createdAt`, `updatedAt`, `isSynced`, `deletedAt`
/// - `syncAction` — persisted as enum name string
/// - `deviceId`, `version`
@collection
class DebugPingIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String message;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  /// Persisted as [SyncAction.name] — use [syncActionEnum] to read as enum.
  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static DebugPingIsar create({
    required String message,
    required String deviceId,
  }) {
    final now = DateTime.now();
    return DebugPingIsar()
      ..uuid = const Uuid().v4()
      ..message = message
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  DebugPingIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  DebugPingIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
