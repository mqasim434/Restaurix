import '../../../core/sync/sync_action.dart';
import '../../../domain/models/credit_customer.dart';
import '../collections/credit_customer_isar.dart';

CreditCustomer creditCustomerFromIsar(CreditCustomerIsar record) {
  return CreditCustomer(
    id: record.uuid,
    fullName: record.fullName,
    phone: record.phone,
    addressLine1: record.addressLine1,
    addressLine2: record.addressLine2,
    city: record.city,
    postcode: record.postcode,
    notes: record.notes,
    balance: record.balance,
    creditLimit: record.creditLimit,
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

void applyCreditCustomerFieldsToIsar({
  required CreditCustomerIsar record,
  required CreditCustomer customer,
}) {
  record
    ..fullName = customer.fullName
    ..phone = customer.phone
    ..addressLine1 = customer.addressLine1
    ..addressLine2 = customer.addressLine2
    ..city = customer.city
    ..postcode = customer.postcode
    ..notes = customer.notes
    ..balance = customer.balance
    ..creditLimit = customer.creditLimit
    ..isActive = customer.isActive
    ..createdAt = customer.createdAt
    ..updatedAt = customer.updatedAt;
}

CreditCustomerIsar applyCreditCustomerToIsar({
  required CreditCustomerIsar record,
  required CreditCustomer customer,
  required String deviceId,
  required SyncAction action,
}) {
  applyCreditCustomerFieldsToIsar(record: record, customer: customer);
  record.markUpdated(deviceId: deviceId, action: action);
  return record;
}
