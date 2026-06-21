import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

class Product implements SyncableEntity {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.basePrice,
    this.description,
    this.imageUrl,
    required this.isAvailable,
    required this.kitchenCategory,
    this.printerId,
    this.modifierGroupIds = const [],
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
  final String categoryId;
  final double basePrice;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final String kitchenCategory;
  final String? printerId;
  final List<String> modifierGroupIds;

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

  Product copyWith({
    String? name,
    String? categoryId,
    double? basePrice,
    String? description,
    bool clearDescription = false,
    String? imageUrl,
    bool clearImageUrl = false,
    bool? isAvailable,
    String? kitchenCategory,
    String? printerId,
    bool clearPrinterId = false,
    List<String>? modifierGroupIds,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      basePrice: basePrice ?? this.basePrice,
      description: clearDescription ? null : (description ?? this.description),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      isAvailable: isAvailable ?? this.isAvailable,
      kitchenCategory: kitchenCategory ?? this.kitchenCategory,
      printerId: clearPrinterId ? null : (printerId ?? this.printerId),
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
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
