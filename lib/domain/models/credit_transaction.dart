import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';
import 'order_enums.dart';

enum CreditTransactionType {
  orderCharge,
  orderReversal,
  payment,
  adjustment,
}

extension CreditTransactionTypeX on CreditTransactionType {
  String get wireValue => switch (this) {
        CreditTransactionType.orderCharge => 'order_charge',
        CreditTransactionType.orderReversal => 'order_reversal',
        CreditTransactionType.payment => 'payment',
        CreditTransactionType.adjustment => 'adjustment',
      };

  String get label => switch (this) {
        CreditTransactionType.orderCharge => 'Order charge',
        CreditTransactionType.orderReversal => 'Order reversal',
        CreditTransactionType.payment => 'Payment',
        CreditTransactionType.adjustment => 'Adjustment',
      };

  static CreditTransactionType fromWire(String value) =>
      CreditTransactionType.values.firstWhere(
        (type) => type.wireValue == value,
        orElse: () => CreditTransactionType.adjustment,
      );
}

class CreditTransaction implements SyncableEntity {
  const CreditTransaction({
    required this.id,
    required this.creditCustomerId,
    this.orderId,
    required this.transactionType,
    required this.amount,
    required this.balanceDelta,
    required this.balanceAfter,
    this.paymentType,
    this.notes,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.deletedAt,
    required this.syncAction,
    required this.deviceId,
    required this.version,
  });

  @override
  final String id;
  final String creditCustomerId;
  final String? orderId;
  final CreditTransactionType transactionType;
  final double amount;
  final double balanceDelta;
  final double balanceAfter;
  final PaymentType? paymentType;
  final String? notes;
  final String createdByUserId;

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final bool isSynced;
  @override
  final DateTime? deletedAt;
  @override
  final SyncAction syncAction;
  @override
  final String deviceId;
  @override
  final int version;

  bool get increasesBalance => balanceDelta > 0;
}
