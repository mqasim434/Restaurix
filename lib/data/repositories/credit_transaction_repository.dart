import 'package:isar/isar.dart';

import '../../domain/models/credit_transaction.dart';
import '../local/collections/credit_transaction_isar.dart';
import '../local/mappers/credit_transaction_mapper.dart';

class CreditTransactionRepository {
  CreditTransactionRepository(this._isar);

  final Isar _isar;

  Stream<List<CreditTransaction>> watchByCustomerId(String customerId) {
    return _isar.creditTransactionIsars
        .filter()
        .deletedAtIsNull()
        .creditCustomerIdEqualTo(customerId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((records) => records.map(creditTransactionFromIsar).toList());
  }

  Future<List<CreditTransaction>> findByCustomerId(String customerId) async {
    final records = await _isar.creditTransactionIsars
        .filter()
        .deletedAtIsNull()
        .creditCustomerIdEqualTo(customerId)
        .sortByCreatedAtDesc()
        .findAll();
    return records.map(creditTransactionFromIsar).toList();
  }

  Future<CreditTransaction?> findOrderCharge(String orderId) async {
    final record = await _isar.creditTransactionIsars
        .filter()
        .deletedAtIsNull()
        .orderIdEqualTo(orderId)
        .transactionTypeEqualTo(CreditTransactionType.orderCharge.wireValue)
        .findFirst();
    if (record == null) return null;
    return creditTransactionFromIsar(record);
  }

  Future<CreditTransaction?> findOrderReversal(String orderId) async {
    final record = await _isar.creditTransactionIsars
        .filter()
        .deletedAtIsNull()
        .orderIdEqualTo(orderId)
        .transactionTypeEqualTo(CreditTransactionType.orderReversal.wireValue)
        .findFirst();
    if (record == null) return null;
    return creditTransactionFromIsar(record);
  }

}
