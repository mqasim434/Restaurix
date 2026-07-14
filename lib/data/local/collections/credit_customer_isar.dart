import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_action.dart';

part 'credit_customer_isar.g.dart';

@collection
class CreditCustomerIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String fullName;

  String? phone;
  String? addressLine1;
  String? addressLine2;
  String? city;
  String? postcode;
  String? notes;

  double balance = 0;

  double? creditLimit;

  @Index()
  bool isActive = true;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isSynced = false;

  DateTime? deletedAt;

  late String syncAction;

  late String deviceId;

  int version = 1;

  @ignore
  SyncAction get syncActionEnum => SyncAction.values.byName(syncAction);

  @ignore
  bool get isDeleted => deletedAt != null;

  static CreditCustomerIsar create({
    required String fullName,
    required String deviceId,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postcode,
    String? notes,
    double? creditLimit,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return CreditCustomerIsar()
      ..uuid = const Uuid().v4()
      ..fullName = fullName
      ..phone = phone
      ..addressLine1 = addressLine1
      ..addressLine2 = addressLine2
      ..city = city
      ..postcode = postcode
      ..notes = notes
      ..balance = 0
      ..creditLimit = creditLimit
      ..isActive = isActive
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..syncAction = SyncAction.create.name
      ..deviceId = deviceId
      ..version = 1;
  }

  CreditCustomerIsar markUpdated({required String deviceId, SyncAction? action}) {
    updatedAt = DateTime.now();
    isSynced = false;
    syncAction = (action ?? SyncAction.update).name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }

  CreditCustomerIsar markDeleted({required String deviceId}) {
    deletedAt = DateTime.now();
    updatedAt = deletedAt!;
    isSynced = false;
    syncAction = SyncAction.delete.name;
    this.deviceId = deviceId;
    version += 1;
    return this;
  }
}
