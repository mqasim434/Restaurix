/// Pattern for standard sync fields on every Isar collection.
///
/// Each collection declares:
/// - [Isar.autoIncrement] `isarId` — internal Isar primary key
/// - `uuid` — universal string identifier (maps to [SyncableEntity.id])
/// - `createdAt`, `updatedAt`, `isSynced`, `deletedAt`
/// - `syncAction` — stored as `@enumerated` [SyncAction]
/// - `deviceId`, `version`
///
/// See [DebugPingIsar] for the reference implementation.
library;

export 'collections/debug_ping_isar.dart';
export 'device_id_service.dart';
export 'isar_service.dart';
