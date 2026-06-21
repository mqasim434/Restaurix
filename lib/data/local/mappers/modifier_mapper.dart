import '../../../core/sync/sync_action.dart';
import '../../../domain/models/item_modifier.dart';
import '../../../domain/models/modifier_group.dart';
import '../collections/item_modifier_isar.dart';
import '../collections/modifier_group_isar.dart';

ModifierGroup modifierGroupFromIsar(ModifierGroupIsar record) {
  return ModifierGroup(
    id: record.uuid,
    name: record.name,
    selectionType: record.selectionTypeEnum,
    isRequired: record.isRequired,
    minSelections: record.minSelections,
    maxSelections: record.maxSelections,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

ModifierGroupIsar applyModifierGroupToIsar({
  required ModifierGroupIsar record,
  required ModifierGroup group,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = group.name
    ..selectionType = group.selectionType.name
    ..isRequired = group.isRequired
    ..minSelections = group.minSelections
    ..maxSelections = group.maxSelections
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}

ItemModifier itemModifierFromIsar(ItemModifierIsar record) {
  return ItemModifier(
    id: record.uuid,
    groupId: record.groupId,
    name: record.name,
    priceDelta: record.priceDelta,
    sortOrder: record.sortOrder,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

ItemModifierIsar applyItemModifierToIsar({
  required ItemModifierIsar record,
  required ItemModifier modifier,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = modifier.name
    ..priceDelta = modifier.priceDelta
    ..sortOrder = modifier.sortOrder
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
