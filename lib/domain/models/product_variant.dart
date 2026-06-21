import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

class ProductVariant implements SyncableEntity {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.sortOrder,
    required this.isDefault,
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

  final String productId;
  final String name;
  final double price;
  final int sortOrder;
  final bool isDefault;

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

  ProductVariant copyWith({
    String? name,
    double? price,
    int? sortOrder,
    bool? isDefault,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return ProductVariant(
      id: id,
      productId: productId,
      name: name ?? this.name,
      price: price ?? this.price,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
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
