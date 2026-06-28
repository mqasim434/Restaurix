import '../settings/app_setting_keys.dart';
import '../../data/repositories/app_setting_repository.dart';
import 'sync_queue_models.dart';

/// Persists per-entity download cursors and global sync metadata.
class SyncCursorStore {
  SyncCursorStore(this._settings);

  final AppSettingRepository _settings;

  static String entityCursorKey(SyncEntityType type) =>
      '${AppSettingKeys.syncEntityCursorPrefix}.${type.name}';

  Future<DateTime?> getEntityCursor(SyncEntityType type) async {
    final raw = await _settings.getString(entityCursorKey(type));
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.parse(raw).toLocal();
  }

  Future<void> setEntityCursor(SyncEntityType type, DateTime value) {
    return _settings.setString(
      entityCursorKey(type),
      value.toUtc().toIso8601String(),
    );
  }

  Future<DateTime?> getLastSuccessfulSyncAt() async {
    final raw = await _settings.getString(AppSettingKeys.syncLastSuccessfulAt);
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.parse(raw).toLocal();
  }

  Future<void> setLastSuccessfulSyncAt(DateTime value) {
    return _settings.setString(
      AppSettingKeys.syncLastSuccessfulAt,
      value.toUtc().toIso8601String(),
    );
  }

  Future<String?> getStoredConflictLog() {
    return _settings.getString(AppSettingKeys.syncConflictLog);
  }

  Future<void> saveConflictLog(String encoded) {
    return _settings.setString(AppSettingKeys.syncConflictLog, encoded);
  }
}
