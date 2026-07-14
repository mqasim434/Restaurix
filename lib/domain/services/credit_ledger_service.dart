import 'package:isar/isar.dart';

import '../../domain/models/credit_transaction.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_enums.dart';
import '../../data/local/collections/credit_customer_isar.dart';
import '../../data/local/collections/credit_transaction_isar.dart';
import '../../data/local/collections/order_isar.dart';
import '../../data/repositories/credit_transaction_repository.dart';

class CreditLedgerException implements Exception {
  CreditLedgerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Posts order charges, reversals, and settlement payments for credit accounts.
class CreditLedgerService {
  CreditLedgerService({
    required Isar isar,
    required CreditTransactionRepository transactionRepository,
  })  : _isar = isar,
        _transactionRepository = transactionRepository;

  final Isar _isar;
  final CreditTransactionRepository _transactionRepository;

  Future<void> processPendingOrderCharges() async {
    final orders = await _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    for (final record in orders) {
      if (record.creditCustomerId == null ||
          record.creditCustomerId!.isEmpty ||
          record.paymentType != PaymentType.credit.name) {
        continue;
      }
      if (record.status == OrderStatus.cancelled.name) continue;

      await chargeForOrderId(
        orderId: record.uuid,
        creditCustomerId: record.creditCustomerId!,
        amount: record.total,
        createdByUserId: record.createdByUserId,
        deviceId: record.deviceId,
      );
    }
  }

  Future<void> chargeForOrder({
    required Order order,
    required String deviceId,
  }) async {
    final customerId = order.creditCustomerId;
    if (customerId == null || order.paymentType != PaymentType.credit) {
      return;
    }
    if (order.status == OrderStatus.cancelled) return;

    await chargeForOrderId(
      orderId: order.id,
      creditCustomerId: customerId,
      amount: order.total,
      createdByUserId: order.createdByUserId,
      deviceId: deviceId,
    );
  }

  Future<void> chargeForOrderId({
    required String orderId,
    required String creditCustomerId,
    required double amount,
    required String createdByUserId,
    required String deviceId,
  }) async {
    if (amount <= 0) return;

    final existing = await _transactionRepository.findOrderCharge(orderId);
    if (existing != null) return;

    await _isar.writeTxn(() async {
      final customerRecord = await _isar.creditCustomerIsars
          .filter()
          .uuidEqualTo(creditCustomerId)
          .findFirst();
      if (customerRecord == null || customerRecord.isDeleted) {
        throw CreditLedgerException('Credit customer not found');
      }
      if (!customerRecord.isActive) {
        throw CreditLedgerException('Credit customer is inactive');
      }

      final newBalance = customerRecord.balance + amount;
      if (customerRecord.creditLimit != null &&
          newBalance > customerRecord.creditLimit!) {
        throw CreditLedgerException('Credit limit exceeded');
      }

      final transaction = CreditTransactionIsar.create(
        creditCustomerId: creditCustomerId,
        transactionType: CreditTransactionType.orderCharge,
        amount: amount,
        balanceDelta: amount,
        balanceAfter: newBalance,
        createdByUserId: createdByUserId,
        deviceId: deviceId,
        orderId: orderId,
        notes: 'Order charge',
      );

      customerRecord
        ..balance = newBalance
        ..markUpdated(deviceId: deviceId);

      await _isar.creditCustomerIsars.put(customerRecord);
      await _isar.creditTransactionIsars.put(transaction);
    });
  }

  Future<void> reverseOrderCharge({
    required Order order,
    required String deviceId,
    required String createdByUserId,
  }) async {
    final customerId = order.creditCustomerId;
    if (customerId == null || order.paymentType != PaymentType.credit) {
      return;
    }

    final existingCharge = await _transactionRepository.findOrderCharge(order.id);
    if (existingCharge == null) return;

    final existingReversal =
        await _transactionRepository.findOrderReversal(order.id);
    if (existingReversal != null) return;

    await _isar.writeTxn(() async {
      final customerRecord = await _isar.creditCustomerIsars
          .filter()
          .uuidEqualTo(customerId)
          .findFirst();
      if (customerRecord == null || customerRecord.isDeleted) return;

      final delta = -existingCharge.amount;
      final newBalance = (customerRecord.balance + delta)
          .clamp(0.0, double.infinity)
          .toDouble();

      final transaction = CreditTransactionIsar.create(
        creditCustomerId: customerId,
        transactionType: CreditTransactionType.orderReversal,
        amount: existingCharge.amount,
        balanceDelta: delta,
        balanceAfter: newBalance,
        createdByUserId: createdByUserId,
        deviceId: deviceId,
        orderId: order.id,
        notes: 'Cancelled order reversal',
      );

      customerRecord
        ..balance = newBalance
        ..markUpdated(deviceId: deviceId);

      await _isar.creditCustomerIsars.put(customerRecord);
      await _isar.creditTransactionIsars.put(transaction);
    });
  }

  Future<void> recordPayment({
    required String creditCustomerId,
    required double amount,
    required PaymentType paymentType,
    required String createdByUserId,
    required String deviceId,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw CreditLedgerException('Payment amount must be greater than zero');
    }

    await _isar.writeTxn(() async {
      final customerRecord = await _isar.creditCustomerIsars
          .filter()
          .uuidEqualTo(creditCustomerId)
          .findFirst();
      if (customerRecord == null || customerRecord.isDeleted) {
        throw CreditLedgerException('Credit customer not found');
      }

      final delta = -amount;
      final newBalance = (customerRecord.balance + delta)
          .clamp(0.0, double.infinity)
          .toDouble();

      final transaction = CreditTransactionIsar.create(
        creditCustomerId: creditCustomerId,
        transactionType: CreditTransactionType.payment,
        amount: amount,
        balanceDelta: delta,
        balanceAfter: newBalance,
        createdByUserId: createdByUserId,
        deviceId: deviceId,
        paymentType: paymentType.name,
        notes: notes?.trim(),
      );

      customerRecord
        ..balance = newBalance
        ..markUpdated(deviceId: deviceId);

      await _isar.creditCustomerIsars.put(customerRecord);
      await _isar.creditTransactionIsars.put(transaction);
    });
  }
}
