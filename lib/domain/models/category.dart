import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

class Category implements SyncableEntity {
  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.sortOrder,
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
  final String? imageUrl;
  final int sortOrder;
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

  Category copyWith({
    String? name,
    String? imageUrl,
    bool clearImageUrl = false,
    int? sortOrder,
    bool? isActive,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
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
