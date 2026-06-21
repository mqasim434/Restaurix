import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

/// A selectable option within a [ModifierGroup] (e.g. "Extra Cheese", "No Onion").
class ItemModifier implements SyncableEntity {
  const ItemModifier({
    required this.id,
    required this.groupId,
    required this.name,
    required this.priceDelta,
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
  final String groupId;
  final String name;
  final double priceDelta;
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

  ItemModifier copyWith({
    String? name,
    double? priceDelta,
    int? sortOrder,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return ItemModifier(
      id: id,
      groupId: groupId,
      name: name ?? this.name,
      priceDelta: priceDelta ?? this.priceDelta,
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
