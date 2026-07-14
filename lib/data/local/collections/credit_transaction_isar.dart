import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';
import '../../../domain/models/credit_transaction.dart';

part 'credit_transaction_isar.g.dart';

@collection
class CreditTransactionIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String creditCustomerId;

  @Index()
  String? orderId;

  late String transactionType;

  double amount = 0;
  double balanceDelta = 0;
  double balanceAfter = 0;

  String? paymentType;
  String? notes;
  late String createdByUserId;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  CreditTransactionType get transactionTypeEnum =>
      CreditTransactionTypeX.fromWire(transactionType);

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static CreditTransactionIsar create({
    required String creditCustomerId,
    required CreditTransactionType transactionType,
    required double amount,
    required double balanceDelta,
    required double balanceAfter,
    required String createdByUserId,
    required String deviceId,
    String? orderId,
    String? paymentType,
    String? notes,
  }) {
    final now = DateTime.now();
    return CreditTransactionIsar()
      ..uuid = const Uuid().v4()
      ..creditCustomerId = creditCustomerId
      ..orderId = orderId
      ..transactionType = transactionType.wireValue
      ..amount = amount
      ..balanceDelta = balanceDelta
      ..balanceAfter = balanceAfter
      ..paymentType = paymentType
      ..notes = notes
      ..createdByUserId = createdByUserId
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  CreditTransactionIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
