import '../../../core/sync/sync_action.dart';
import '../../../domain/models/product_variant.dart';
import '../collections/product_variant_isar.dart';

ProductVariant productVariantFromIsar(ProductVariantIsar record) {
  return ProductVariant(
    id: record.uuid,
    productId: record.productId,
    name: record.name,
    price: record.price,
    sortOrder: record.sortOrder,
    isDefault: record.isDefault,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

ProductVariantIsar applyVariantToIsar({
  required ProductVariantIsar record,
  required ProductVariant variant,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = variant.name
    ..price = variant.price
    ..sortOrder = variant.sortOrder
    ..isDefault = variant.isDefault
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
