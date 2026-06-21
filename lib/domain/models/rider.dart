import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

/// Delivery rider — extended in Module 13.
class Rider implements SyncableEntity {
  const Rider({
    required this.id,
    required this.name,
    this.phone,
    required this.isActive,
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
  final String name;
  final String? phone;
  final bool isActive;

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
