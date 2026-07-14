import '../../../domain/models/credit_transaction.dart';
import '../../../domain/models/order_enums.dart';
import '../collections/credit_transaction_isar.dart';

CreditTransaction creditTransactionFromIsar(CreditTransactionIsar record) {
  return CreditTransaction(
    id: record.uuid,
    creditCustomerId: record.creditCustomerId,
    orderId: record.orderId,
    transactionType: record.transactionTypeEnum,
    amount: record.amount,
    balanceDelta: record.balanceDelta,
    balanceAfter: record.balanceAfter,
    paymentType: record.paymentType == null
        ? null
        : PaymentType.values.byName(record.paymentType!),
    notes: record.notes,
    createdByUserId: record.createdByUserId,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    isSynced: record.isSynced,
    deletedAt: record.deletedAt,
    syncAction: record.syncActionEnum,
    deviceId: record.deviceId,
    version: record.version,
  );
}
