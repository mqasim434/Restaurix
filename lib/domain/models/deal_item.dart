import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

class DealItem implements SyncableEntity {
  const DealItem({
    required this.id,
    required this.dealId,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.allowModifiers,
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
  final String dealId;
  final String productId;
  final String? variantId;
  final int quantity;
  final bool allowModifiers;

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

  DealItem copyWith({
    String? productId,
    String? variantId,
    bool clearVariantId = false,
    int? quantity,
    bool? allowModifiers,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return DealItem(
      id: id,
      dealId: dealId,
      productId: productId ?? this.productId,
      variantId: clearVariantId ? null : (variantId ?? this.variantId),
      quantity: quantity ?? this.quantity,
      allowModifiers: allowModifiers ?? this.allowModifiers,
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
