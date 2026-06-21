import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';
import 'deal_availability.dart';
import 'deal_item.dart';
import 'product.dart';

class Deal implements SyncableEntity {
  const Deal({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.categoryId,
    required this.price,
    required this.isAvailable,
    this.availabilityStart,
    this.availabilityEnd,
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
  final String? description;
  final String? imageUrl;
  final String? categoryId;
  final double price;
  final bool isAvailable;
  final DateTime? availabilityStart;
  final DateTime? availabilityEnd;

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

  /// Whether [now] falls inside the configured availability window.
  bool isWithinAvailabilityWindow({DateTime? at}) {
    return DealAvailability.isWithinWindow(
      start: availabilityStart,
      end: availabilityEnd,
      at: at,
    );
  }

  /// Checks manual flag, time window, and all constituent products.
  bool isEffectivelyAvailable({
    required List<DealItem> items,
    required Map<String, Product> productsById,
    DateTime? at,
  }) {
    return DealAvailability.isEffectivelyAvailable(
      deal: this,
      items: items,
      productsById: productsById,
      at: at,
    );
  }

  Deal copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    String? imageUrl,
    bool clearImageUrl = false,
    String? categoryId,
    bool clearCategoryId = false,
    double? price,
    bool? isAvailable,
    DateTime? availabilityStart,
    bool clearAvailabilityStart = false,
    DateTime? availabilityEnd,
    bool clearAvailabilityEnd = false,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return Deal(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      availabilityStart: clearAvailabilityStart
          ? null
          : (availabilityStart ?? this.availabilityStart),
      availabilityEnd: clearAvailabilityEnd
          ? null
          : (availabilityEnd ?? this.availabilityEnd),
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
