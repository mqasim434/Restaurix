import '../../../core/sync/sync_action.dart';
import '../../../domain/models/pickup_company.dart';
import '../../../domain/models/rider.dart';
import '../collections/pickup_company_isar.dart';
import '../collections/rider_isar.dart';

Rider riderFromIsar(RiderIsar record) {
  return Rider(
    id: record.uuid,
    name: record.name,
    phone: record.phone,
    isActive: record.isActive,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

RiderIsar applyRiderToIsar({
  required RiderIsar record,
  required Rider rider,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = rider.name
    ..phone = rider.phone
    ..isActive = rider.isActive
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}

PickupCompany pickupCompanyFromIsar(PickupCompanyIsar record) {
  return PickupCompany(
    id: record.uuid,
    name: record.name,
    logoUrl: record.logoUrl,
    isActive: record.isActive,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}

PickupCompanyIsar applyPickupCompanyToIsar({
  required PickupCompanyIsar record,
  required PickupCompany company,
  required String deviceId,
  required SyncAction action,
}) {
  record
    ..name = company.name
    ..logoUrl = company.logoUrl
    ..isActive = company.isActive
    ..markUpdated(deviceId: deviceId, action: action);
  return record;
}
