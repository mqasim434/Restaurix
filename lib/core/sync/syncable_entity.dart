import 'sync_action.dart';

/// Standard sync fields shared by every Isar collection and domain model.
abstract mixin class SyncableEntity {
  /// Universal identifier (UUID, client-generated for offline creation).
  String get id;

  DateTime get createdAt;

  DateTime get updatedAt;

  /// Whether this record has been successfully synced to the remote backend.
  bool get isSynced;

  /// Soft-delete timestamp; null means the record is active.
  DateTime? get deletedAt;

  SyncAction get syncAction;

  /// Device that last modified this record.
  String get deviceId;

  /// Incremented on every local write; used for conflict resolution.
  int get version;
}
