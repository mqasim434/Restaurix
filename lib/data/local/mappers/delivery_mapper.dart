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
