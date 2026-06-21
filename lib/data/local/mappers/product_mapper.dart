import '../../../core/sync/sync_action.dart';
import '../../../domain/models/product.dart';
import '../collections/product_isar.dart';

Product productFromIsar(ProductIsar record) {
  return Product(
    id: record.uuid,
    name: record.name,
    categoryId: record.categoryId,
    basePrice: record.basePrice,
    description: record.description,
    imageUrl: record.imageUrl,
    isAvailable: record.isAvailable,
    kitchenCategory: record.kitchenCategory,
    printerId: record.printerId,
    modifierGroupIds: List.unmodifiable(record.modifierGroupIds),
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

ProductIsar applyProductToIsar({
  required ProductIsar record,
  required Product product,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = product.name
    ..categoryId = product.categoryId
    ..basePrice = product.basePrice
    ..description = product.description
    ..imageUrl = product.imageUrl
    ..isAvailable = product.isAvailable
    ..kitchenCategory = product.kitchenCategory
    ..printerId = product.printerId
    ..modifierGroupIds = List.of(product.modifierGroupIds)
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
