import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';
import 'table_status.dart';

class RestaurantTable implements SyncableEntity {
  const RestaurantTable({
    required this.id,
    required this.hallId,
    required this.label,
    required this.capacity,
    required this.status,
    this.currentOrderId,
    required this.sortOrder,
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
  final String hallId;
  final String label;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;
  final int sortOrder;

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

  bool get hasActiveOrder =>
      status == TableStatus.occupied && currentOrderId != null;

  RestaurantTable copyWith({
    String? label,
    int? capacity,
    TableStatus? status,
    String? currentOrderId,
    bool clearCurrentOrderId = false,
    int? sortOrder,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return RestaurantTable(
      id: id,
      hallId: hallId,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId:
          clearCurrentOrderId ? null : (currentOrderId ?? this.currentOrderId),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
      syncAction: syncAction ?? this.syncAction,
      deviceId: deviceId ?? this.deviceId,
      version: version ?? this.version,
    );
  }
}
