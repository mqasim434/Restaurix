import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

class DraftOrder implements SyncableEntity {
  const DraftOrder({
    required this.id,
    this.label,
    required this.payloadJson,
    this.tableId,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.deletedAt,
    required this.syncAction,
    required this.deviceId,
    required this.version,
  });

  @override
  final String id;
  final String? label;
  final String payloadJson;
  final String? tableId;
  final String createdByUserId;

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final bool isSynced;
  @override
  final DateTime? deletedAt;
  @override
  final SyncAction syncAction;
  @override
  final String deviceId;
  @override
  final int version;
}
