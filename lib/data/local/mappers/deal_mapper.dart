import '../../../core/sync/sync_action.dart';
import '../../../domain/models/deal.dart';
import '../../../domain/models/deal_item.dart';
import '../collections/deal_isar.dart';
import '../collections/deal_item_isar.dart';

Deal dealFromIsar(DealIsar record) {
  return Deal(
    id: record.uuid,
    name: record.name,
    description: record.description,
    imageUrl: record.imageUrl,
    categoryId: record.categoryId,
    price: record.price,
    isAvailable: record.isAvailable,
    availabilityStart: record.availabilityStart,
    availabilityEnd: record.availabilityEnd,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

DealIsar applyDealToIsar({
  required DealIsar record,
  required Deal deal,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = deal.name
    ..description = deal.description
    ..imageUrl = deal.imageUrl
    ..categoryId = deal.categoryId
    ..price = deal.price
    ..isAvailable = deal.isAvailable
    ..availabilityStart = deal.availabilityStart
    ..availabilityEnd = deal.availabilityEnd
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}

DealItem dealItemFromIsar(DealItemIsar record) {
  return DealItem(
    id: record.uuid,
    dealId: record.dealId,
    productId: record.productId,
    variantId: record.variantId,
    quantity: record.quantity,
    allowModifiers: record.allowModifiers,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

DealItemIsar applyDealItemToIsar({
  required DealItemIsar record,
  required DealItem item,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..productId = item.productId
    ..variantId = item.variantId
    ..quantity = item.quantity
    ..allowModifiers = item.allowModifiers
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
